#encoding: utf-8

# カッコを処理するクラス
module Regtest::Front::Parenthesis
  
  class Paren
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    # コンストラクタ
    def initialize(paren_start, element, paren_end)
      @options = @@parse_options
      @paren_type = paren_start[0]
      @offset = paren_start[1]
      @length = (paren_end[1] - paren_start[1]) + paren_end[2]
      @prefix = @paren_type.sub(/^\(\??/, "")    # 先頭の（と？は削除
      @name = get_name(@prefix)
      @condition = nil  # set at generating json
      @refer_name = nil
      TstLog("Parenthesis: name:#{@name}, offset:#{@offset}, element:#{element}")
      @element = element
      @generated_string = []
      @nest = 0
    end
    
    attr_reader :prefix, :name, :refer_name, :offset, :length

    # カッコの名前がある場合
    def get_name(prefix)
      if(md = prefix.match(/^[<'](\w+)[>']$/))
        md[1]
      else
        nil
      end
    end

    # 条件の場合
    def get_condition(prefix)
      puts "prefix: #{prefix}"
      if(md = prefix.match(/^\((\d+)\)$/))
        condition_name = @options[:parens].get_paren(md[1].to_i)
        if !condition_name
          raise "condition number #{prefix} is invalid"
        end
      elsif(md = prefix.match(/^\(<(\w+)>\)|\('(\w+)'\)$/))
        match_string = md[1] || md[2]
        condition_name = @options[:parens].get_paren(match_string)
        if !condition_name
          raise "condition name (#{match_string}) is not found"
        end
      else
        condition_name = nil
      end
      
      # check number of elements
      if(condition_name)
        if(Regtest::Front::Selectable::Selectable === @element)
          if(@element.nominates.size > 2)
            raise "invalid condition. 1 or 2 selectable elements"
          end
        end
      end
      
      condition_name
    end

    # 数字で後方参照する名前の設定
    def set_refer_name(name)
      @refer_name = name
    end

    # 文字列の生成
    def generate
      string = @element.generate
      @generated_string.push string
      string
    end
    
    # 生成済みの文字列を得る
    def get_value(relative_num = 0)
      # print "gen: "; pp @generated_string
      if(@generated_string.size > 0)
        @generated_string[-1]
      else
        warn "Error: refer uninitialized parenthesis"
        nil
      end
    end
    
    # 結果のリセット
    def reset
      @generated_string = []
      @nest = 0
      @element.reset
    end
    
    # JSONへの変換
    def json
      @condition = get_condition(@prefix)
      condition_name = @condition.refer_name if @condition
      @@id += 1
      "{\"type\": \"LEX_PAREN\"," +
      " \"name\": \"#{@name}\"," +
      " \"offset\": \"#{@offset}\"," +
      " \"length\": \"#{@length}\"," +
      " \"prefix\": \"#{@prefix}\"," +
      " \"refer_name\": \"#{@refer_name}\"," +
      " \"condition_name\": \"#{condition_name}\"," +
      " \"id\": \"p#{@@id}\", " +
      " \"value\": #{@element.json}" +
      "}"
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

