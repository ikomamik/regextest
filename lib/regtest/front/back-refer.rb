# encoding: utf-8

# Parse back refer element (\1, \k<foo> etc.)
module Regtest::Front::BackRefer
  class BackRefer
    include Regtest::Common
    @@id = 0   # 一意の名称を生成するための番号
    
    # コンストラクタ
    def initialize(type, value)
      TstLog("BackRefer: #{type} #{value}")
      @type = type
      @value = value[0]
      @offset = value[1]
      @length = value[2]
      @options = @@parse_options
      @paren_obj = nil
      @relative_num = nil
      
      # この段階では、カッコが無い場合があるので生成時にチェック
      #if(!@paren_obj)
      #  raise "Error: parenthesis #{@value} not found"
      #end
    end
    
    attr_reader :offset, :length
    
    # 対応するかっこのオブジェクトを得る
    def get_paren(type, value)
      case type
      when :LEX_BACK_REFER    #  \[1-9]のパターン
        if(md = value.match(/^\\(\d+)$/))
          @paren_obj = @options[:parens].get_paren(md[1].to_i)
        else
          raise "Error: Internal error, invalid back reference"
        end
      when :LEX_NAMED_REFER   # \k<foo>のパターン
        if(md = value.match(/^\\k[<'](\w+)(?:([\+\-]\d+))?[>']$/))
          @paren_obj = @options[:parens].get_paren(md[1])
          if(md[2])
            @relative_num = md[2].to_i
          end
        else
          raise "Error: Internal error, invalid named reference"
        end
      when :LEX_NAMED_GENERATE # \g<foo>のパターン
        if(md = value.match(/^\\g[<'](\w+)[>']$/))
          @paren_obj = @options[:parens].get_paren(md[1])
          if(!@paren_obj && md[1].match(/^\d+$/))
            @paren_obj = @options[:parens].get_paren(md[1].to_i)
          end
        else
          raise "Error: Internal error, invalid named reference"
        end
      else
        raise "Error: internal error. unexpected refer type"
      end
      @paren_obj
    end
    
    # 参照のみの場合は新たに生成せずに前に生成した文字列を使う
    def generate
      if(!@paren_obj)
        @paren_obj = get_paren(@type, @value)
        if(!@paren_obj)
          raise "Error: parenthesis #{@value} not found"
        end
      end
      
      if(@type == :LEX_NAMED_GENERATE)
        @paren_obj.generate
      else
        @paren_obj.get_value(@relative_num)
      end
    end
    
    # 結果のリセット
    def reset
      if(@type == :LEX_NAMED_GENERATE)
        @paren_obj = nil
        @relative_num = nil
      end
    end
    
    # JSONへの変換
    def json
      @paren_obj = get_paren(@type, @value)
      if(!@paren_obj)
        raise "Error: parenthesis #{@value} not found"
      end
      @@id += 1
      "{\"type\": \"#{@type}\", " +
       "\"value\": \"#{@value}\", " +
       "\"offset\": \"#{@offset}\", " +
       "\"length\": \"#{@length}\", " +
       "\"name\": \"#{@paren_obj.name}\", " +
      " \"id\": \"c#{@@id}\", " +
       "\"refer_name\": \"#{@paren_obj.refer_name}\", " +
       "\"relative_num\": \"#{@relative_num}\" " +
       "}"
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

