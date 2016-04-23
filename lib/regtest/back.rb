# encoding: utf-8

class Regtest::Back; end
require 'regtest/common'
require 'regtest/regex-option'
require 'regtest/back/element'
require 'regtest/back/result'

class Regtest::Back
  include Regtest::Common
  
  # Constructor
  def initialize(json_obj)
    @reg_options = @@parse_options[:reg_options]
    @reg_source = @@parse_options[:reg_source]
    @json_obj = json_obj
    
    # 名前とオブジェクトの関係を管理するハッシュの作成
    @name_hash = make_name_hash(@json_obj, {})
    
    # テストに必要な情報を得る
    # @test_info = Regtest::Back::TestCase.new(@json_obj, @name_hash)
    
    # ネストの最大数
    @max_nest = (ENV['TST_MAX_RECURSION'])?(ENV['TST_MAX_RECURSION'].to_i):8
  end
  
  # 名前とオブジェクトの関係を管理するハッシュの作成
  def make_name_hash(target, name_hash)
    # idを登録。カッコの場合は参照名も登録する。
    raise "Internal error: found duplicate id #{target["id"]}" if target["id"] && name_hash[target["id"]]
    name_hash[target["id"]] = target
    name_hash[target["refer_name"]] = target if(target["type"] == "LEX_PAREN")
    
    # 再帰的に名称を登録
    if(target["value"])
      if( Array === target["value"])
        target["value"].each{|child| make_name_hash(child, name_hash)}
      else
        make_name_hash(target["value"], name_hash)
      end
    end
    name_hash
  end
  
  # 正規表現にマッチする文字列を生成
  def generate
    @parens_hash = {}  # カッコで生成した値を管理するハッシュ
    @nest = 0          # 後方参照のネスト数
    @quit_mode = false # ネスト数が多くなった時の処理フラグ
    
    # 先方に定義したカッコの参照があるので、まずカッコを探索
    seek_parens(@json_obj)
    
    pre_result = generate_matched_string({json: @json_obj, regopt: @reg_options})
    if(result = check_look_ahead_behind(pre_result))
      if !result.narrow_down
        return nil
      end
      result.fix
    end
    result
  end
  
  # アンカーを考慮して候補を絞る
  def check_look_ahead_behind(nominate_array)
    # pp nominate_array
    results = Regtest::Back::Result.new
    nominate_array.each do | elem |
      command = elem.command
      case command
      when :CMD_SELECT
        results.push_body elem
      when :CMD_LOOK_AHEAD, :CMD_NOT_LOOK_AHEAD
        if(sub_results = check_look_ahead_behind(elem.param[:result]))
          results.add_look_ahead(command, sub_results)
        else
          return nil
        end
      when :CMD_LOOK_BEHIND, :CMD_NOT_LOOK_BEHIND
        if(sub_results = check_look_ahead_behind(elem.param[:result]))
          results.add_look_behind(command, sub_results)
        else
          return nil
        end
      when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
           :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END, :CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START  
        results.add_anchor(command)
      else
        raise "invalid command: #{command}"
      end
    end
    results.merge
    
    results
  end
  
  # アンカーを考慮して候補を絞る
  def narrow_down_by_anchors_old(nominate_array)
    # pp nominate_array
    results = Regtest::Back::Result.new
    anchors = []
    nominate_array.each do | elem |
      case elem.command
      when :CMD_SELECT
        anchors.each do | anchor_result |
          next if(anchor_result.size == 0)
          if(!elem.intersect(anchor_result.shift))
            return nil
          end
        end
        results.push elem
      when :CMD_LOOK_AHEAD
        if(sub_results = narrow_down_by_anchors(elem.param[:result]))
          sub_results.union_succeedings
          anchors.push sub_results
        else
          return nil
        end
      when :CMD_LOOK_BEHIND
        if(sub_results = narrow_down_by_anchors(elem.param[:result]))
          sub_results.union_proceedings
          results.look_behind(sub_results)
        else
          return nil
        end
      when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
           :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END,:CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START  
        results.add_anchor(elem.command)
      else
        raise "invalid command: #{elem.command}"
      end
    end
    
    # look-ahead in out-of-match
    anchors.each do | anchor_result |
      results.look_ahead_post(anchor_result)
    end
    
    # Checks anchors
    unless results.check_anchors
      return nil
    end
    
    results
  end
  
  # カッコを探索
  def seek_parens(target)
    if(target["type"] == "LEX_PAREN")
      @parens_hash[target["refer_name"]] = {:target => target}
    end
    if(target["value"])
      if( Array === target["value"])
        target["value"].each{|child| seek_parens(child)}
      else
        seek_parens(target["value"])
      end
    end
  end
  
  # 正規表現にマッチするランダムな文字列を生成
  #（テストケースでカバーできない部分で使用）
  def generate_matched_string(param)
    target = param[:json]
    reg_options = param[:regopt]
    result = nil  # 結果の文字列
    case target["type"]
    when "LEX_SEQ"
      cur_options = reg_options.dup   # 途中で書き換わる可能性があるので
      results = []
      target["value"].each do |elem|
        generated_string = generate_matched_string({json: elem, regopt: cur_options})
        if(Array === generated_string)
          generated_string.flatten!(1)
          results += generated_string
        else
          results.push generated_string
        end
      end
      # 一つでも失敗があれば、nil
      if(results.index(nil))
        result = nil
      else
        # result = results.join("")
        result = results
      end
    when "LEX_SELECT"
      if param[:forced_select]
        # index is specified by condition 
        if target["value"][param[:forced_select]]
          result = generate_matched_string({json: target["value"][param[:forced_select]], regopt: reg_options})
        else
          # regexp such as /^(?:b|(a))(?(1)1)$/ match "b"!
          result = []
        end
      else
        # 一つでも値を生成するエントリがあればそれを使う
        offsets = (0 ... target["value"].size).to_a.shuffle
        result = nil
        offsets.each do | offset |
          result = generate_matched_string({json: target["value"][offset], regopt: reg_options})
          break if(result)
        end
      end
      result
    when "LEX_PAREN"
      # カッコ内で有効なオプションの設定
      paren_prefix = target["prefix"]
      # puts target["prefix"]
      if(paren_prefix == "<=")
        lb_result = generate_matched_string({json: target["value"], regopt: reg_options})
        result = Regtest::Back::Element.new({cmd: :CMD_LOOK_BEHIND, result: lb_result})
      elsif(paren_prefix == "=")
        la_result = generate_matched_string({json: target["value"], regopt: reg_options})
        result = Regtest::Back::Element.new({cmd: :CMD_LOOK_AHEAD, result: la_result})
      elsif(paren_prefix == "<!")
        lb_result = generate_matched_string({json: target["value"], regopt: reg_options})
        result = Regtest::Back::Element.new({cmd: :CMD_NOT_LOOK_BEHIND, result: lb_result})
      elsif(paren_prefix == "!")
        la_result = generate_matched_string({json: target["value"], regopt: reg_options})
        result = Regtest::Back::Element.new({cmd: :CMD_NOT_LOOK_AHEAD, result: la_result})
      else
        # 条件を指定時
        select_num = nil
        if(target["condition_name"] && target["condition_name"].length > 0)
          if @parens_hash[target["condition_name"]][:generated]
            select_num = 0
          else
            select_num = 1
          end
        end
        
        if(select_num == 1 && target["value"]["type"] != "LEX_SELECT")
          result = nil
        else
          if(md = paren_prefix.match(/^([imx]*(?:\-[imx]+)?)(:)?$/))
            if(md[2])
              # (?imx: )のパターンの時はdeep copy
              cur_options = reg_options.dup
            else
              # (?imx)のパターンの時は元々のオプションを書き換えてしまう
              cur_options = reg_options
            end
            cur_options.modify(md[1])
          else
            cur_options = reg_options
          end
          
          generate_string = generate_matched_string({json: target["value"], regopt: cur_options, forced_select: select_num})
          
          @parens_hash[target["refer_name"]][:generated] ||= []
          @parens_hash[target["refer_name"]][:generated][@nest] = generate_string
          result = generate_string
        end
      end
    when "LEX_CHAR_CLASS"
      results = Regtest::Back::Element.new({cmd: :CMD_SELECT, data: []})
      target["value"].each do | elem |
        sub_results = generate_matched_string({json: elem, regopt: reg_options})
        results.union sub_results
      end
      result = results
    when "LEX_BRACKET", "LEX_SIMPLIFIED_CLASS", "LEX_ANY_LETTER", "LEX_POSIX_CHAR_CLASS", "LEX_UNICODE_CLASS"
      result = generate_matched_string({json: target["value"], regopt: reg_options})
    when "LEX_REPEAT"
      if(@quit_mode)
        repeat = target["min_repeat"]
      elsif(target["max_repeat"] > target["min_repeat"])
        repeat = target["min_repeat"]+rand(target["max_repeat"]-target["min_repeat"]+1)
      else
        repeat = target["min_repeat"]
      end
      result = []
      # puts "repeat=#{repeat} quit=#{@quit_mode} nest=#{@nest}"
      repeat.times do
        if( elem = generate_matched_string({json: target["value"], regopt: reg_options}))
          result.push elem
        else
          result = nil
          break
        end
      end
    when "LEX_RANGE"
      # result = select_from_range(target["begin"], target["end"], reg_options)
      letter = []
      codepoints = (target["begin"]..target["end"]).to_a
      codepoints.each do | codepoint |
        letter += ignore_case2([codepoint].pack("U*"), reg_options)
      end
      result = Regtest::Back::Element.new({cmd: :CMD_SELECT, data: letter})
    when "LEX_BACK_REFER", "LEX_NAMED_REFER"
      if @parens_hash[target["refer_name"]][:generated]
        relative_num = (target["relative_num"]=="")?(-1):(@nest + target["relative_num"].to_i)
        result = @parens_hash[target["refer_name"]][:generated][relative_num]
      else
        result = nil
      end
    when "LEX_NAMED_GENERATE"
      @quit_mode = true if(@nest >= @max_nest)
      if(@quit_mode)
        result = nil
      else
        @nest += 1
        result = generate_matched_string({json: @parens_hash[target["refer_name"]][:target], regopt: reg_options})
        @nest -= 1
      end
    when "LEX_CHAR"
      # result = ignore_case(target["value"], reg_options)
      letter = ignore_case2(target["value"], reg_options)
      result = Regtest::Back::Element.new({cmd: :CMD_SELECT, data: letter})
    when "LEX_ANC_LINE_BEGIN"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_LINE_BEGIN})
    when "LEX_ANC_LINE_END"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_LINE_END})
    when "LEX_ANC_WORD_BOUND"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_WORD_BOUND})
    when "LEX_ANC_WORD_UNBOUND"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_WORD_UNBOUND})
    when "LEX_ANC_STRING_BEGIN"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_STRING_BEGIN})
    when "LEX_ANC_STRING_END"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_STRING_END})
    when "LEX_ANC_STRING_END2"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_STRING_END2})
    when "LEX_ANC_MATCH_START"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_MATCH_START})
    when "LEX_ANC_LOOK_BEHIND2"
      result = Regtest::Back::Element.new({cmd: :CMD_ANC_LOOK_BEHIND2})
    when "LEX_EMPTY"
      result = []
    else
      raise "#{target["type"]} not implemented (from generate_matched_string routine)"
    end
    result
  end
  
  # 大文字小文字を50%の確率で変換
  def ignore_case2(a_char, reg_options)
    if( reg_options.is_ignore? && a_char.upcase != a_char.downcase)
      [a_char.upcase, a_char.downcase]
    else
      [a_char]
    end
  end
  
  # Rangeから値を選ぶ
  def select_from_range(letter_begin, letter_end, reg_options)
    codepoints = (letter_begin..letter_end).to_a
    offset = rand(codepoints.size)
    ignore_case([codepoints[offset]].pack("U*"), reg_options)
  end
  
  # 大文字小文字を50%の確率で変換
  def ignore_case(a_char, reg_options)
    if( reg_options.is_ignore?)
      (rand(2)==0)?(a_char.upcase):(a_char.downcase)
    else
      a_char
    end
  end
  
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0

end

