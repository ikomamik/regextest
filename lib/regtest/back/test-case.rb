# encoding: utf-8

# ZDDライブラリ
require "nysol/zdd"

# ZDDライブラリを使って制約条件を満たすテストケースを生成
class Regtest::Back::TestCase

  def initialize(json_obj, name_hash)
    @json_obj = json_obj
    @name_hash = name_hash
    @selectables = {}
    @selectable_num = 0
    @constraints = []
    @paren_hash = {}
    @test_cases = nil
    @called_num = 0

    # 解析木をサーチして、選択可能な要素を列挙
    seek_selectable(@json_obj, [])
    enum_selectables
    
    # ZDDを使って制約条件からテストケースを生成
    solve_constraints
  end

  # 解析木をサーチして、選択可能な要素を列挙する
  def seek_selectable(target, stack)
    case target["type"]
    when "LEX_SEQ"
      target["value"].map{|elem| seek_selectable(elem, stack)}
    when "LEX_SELECT"
      if(target["value"].size > 1)
        add_selectable(target, target["value"].size, stack)
        target["value"].each_with_index do |elem, i| 
          stack.push "#{target["id"]}_#{i}"
          seek_selectable(elem, stack)
          stack.pop
        end
      else
        # 一つしかない場合
        seek_selectable(target["value"][0], stack)
      end
    when "LEX_PAREN"
      # 制約条件があるカッコは、その情報を記憶しておく（後方参照用）
      if(stack.size > 0)
        puts "paren id #{target["id"]} stack #{stack[-1]}"
        add_paren(target["id"], stack[-1])
      end
      seek_selectable(target["value"], stack)
    when "LEX_BRACKET", "LEX_SIMPLIFIED_CLASS", "LEX_ANY_LETTER", "LEX_POSIX_CHAR_CLASS"
      seek_selectable(target["value"], stack)
    when "LEX_REPEAT"
      if(target["max_repeat"] > target["min_repeat"]+1)
        add_selectable(target, 3, stack)
      elsif(target["max_repeat"] == target["min_repeat"]+1)
        add_selectable(target, 2, stack)
      elsif(target["max_repeat"] == 0)
        # (foo){0}のパターン
        add_selectable(target, 1, stack)
      end
      
      # 繰り返し数の最小がゼロの場合は省略される可能性があるのでスタックを積む
      if(target["min_repeat"] == 0)
        stack.push "~#{target["id"]}_0"
        seek_selectable(target["value"], stack)
        stack.pop
      else
        seek_selectable(target["value"], stack)
      end
    when "LEX_RANGE"
      # add_selectable(target, stack)
    when "LEX_BACK_REFER", "LEX_NAMED_REFER"
      # constraintsの登録
      referred = @name_hash[target["refer_name"]]["id"]
      raise "Internal error, not found referred parenthesis(#{target["refer_name"]})" if(!referred)
      puts "referred = #{referred}, stack=#{stack}"
      if(stack.size > 0)
        # その後方参照が参照される場合は、参照先も存在している必要がある。
        add_constraint(stack[-1], referred)
      else
        # 無条件に参照先が存在している必要がある
        add_constraint(nil, referred)
      end
    when "LEX_NAMED_GENERATE", "LEX_CHAR", "LEX_UNICODE_CLASS"
      # 処理は不要？
    else
      raise "#{target["type"]} not implemented (from seek_selectable routine)"
    end
  end
  
  # カッコの情報を追加
  def add_paren(paren_id, selectable_id)
    @paren_hash[paren_id] = convert_selectable_id(selectable_id)
  end
  
  # 生成したテストケースから一つのテストを得る
  def get_test_case
    if(@test_cases)
      result = @test_cases[@called_num].dup
      @called_num += 1
      
      # 一巡した場合、シャッフルして最初から
      if(@called_num == @test_cases.size)
        @called_num = 0
        @test_cases.shuffle!
      end
    else
      result = nil
    end
    result
  end
  
  # 制約条件の追加
  def add_constraint(requires_obj, then_obj, else_obj = nil)
    @constraints.push [requires_obj, then_obj, else_obj]
  end
  
  # 制約条件のZDD化
  def refine_constraints
    # pp @constraints
    @constraints.map! do | constraint |
      constraint.map do | elem |
        if(String === elem)
          key = elem.split("_")[0]
          if(@selectables[key])
            ZDD.itemset(elem)
          elsif(@paren_hash[elem])
            convert_to_zdd(@paren_hash[elem])
          else
            # pp @selectables
            # raise "Internal error: cannot convert from #{elem} to selectable"
            nil
          end
        else
          elem
        end
      end
    end
  end
  
  # 制約条件のZDD化（行列表現をZDDの積和形式に変換）
  def convert_to_zdd(elem)
    if Array === elem
      work = ZDD.constant(0)
      elem.each do | elem2 |
        work += ZDD.itemset(elem2)
      end
      work
    else
      ZDD.itemset(elem)
    end
  end
  
  # ~否定の演算子を変換
  def convert_selectable_id(selectable_id)
    if(md = selectable_id.match(/^(~)?(.+?)_(\d+)$/))
      if(md[1])
        # ~付きは、それ以外のもの
        key = md[2]
        num = md[3].to_i
        selectable_ids = (1...@selectables[key][:level]).to_a.map{|num| "#{key}_#{num}"}
      else
       selectable_id
      end
    else
      raise "Internal error: invalid selectable_id #{selectable_id}"
    end
  end
  
  # 選択可能なエントリの列挙
  def enum_selectables
    @selectables.each do | key, value |
      target = value[:target]
      puts "name: #{key}, type: #{target["type"]}, " +
           "requires: #{value[:requires]}, " +
           "level_num: #{value[:level]}"
    end
  end
  
  # 選択可能な要素の登録
  def add_selectable(target, level_num, stack)
    name = target["id"]
    raise "Error: internal error, name not found" if(!name)
    @selectable_num += 1
    @selectables[name] = {:target => target, :requires => stack[-1], :level => level_num}
    name
  end
  
  # 制約条件の簡略化および適用
  def solve_constraints
    
    # 全ての組合せを求める。
    test_set = ZDD.constant(1)
    @selectables.each do | key, value |
      # 通常の値の設定
      params = ZDD.constant(0)
      value[:level].times do | i |
        value_name = "#{key}_#{i}"
        params += ZDD.itemset(value_name)
      end
      
      # 制約がある場合の設定
      if(value[:requires])
        # 省略値の設定
        empty_value = ZDD.itemset("#{key}__")
        # 依存関係のある値があるときは、通常の値。無いときは省略値
        puts value[:requires]
        require_id = convert_selectable_id(value[:requires])
        add_constraint(convert_to_zdd(require_id), params, empty_value)
        params += empty_value
      end
      
      # まず、全ての組わせを求める
      test_set *= params
    end
    test_set.show if(test_set.count < 256)
    puts "whole test_set is #{test_set.count}"
    
    # 制約でテストを減らす
    refine_constraints
    # pp @constraints
    @constraints.each do | constraint |
      if(!constraint[1] && !constraint[2])
        # 何もしない
      elsif(!constraint[0])
        # 無条件制約
        test_set = test_set.restrict(constraint[1])
      elsif(!constraint[2])
        # if then の制約
        test_set = test_set.restrict(constraint[0]).
                   iif(test_set.restrict(constraint[1]), test_set)
      else
        # if then elseの制約
        test_set = test_set.restrict(constraint[0]).
                   iif(test_set.restrict(constraint[1]), test_set.restrict(constraint[2]))
      end
    end
    test_set.show if(test_set.count < 256)
    puts "whole test_set is #{test_set.count}"
    
    if(test_set.same?(ZDD.constant(1)))
      puts "no selectable element"
    else
      @test_cases = test_set.to_a.shuffle.map do | a_test |
        test_case = {}
        a_test.split(/\s+/).each do | item |
          elems = item.split("_")
          test_case[elems[0]] = (elems[1])?(elems[1].to_i):nil
        end
        test_case
      end
    end 
    pp @test_cases if @test_cases
  end
end


# Test suite (execute when this file is specified in command line)
if __FILE__ == $0

end

