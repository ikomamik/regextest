# encoding: utf-8

# Parse back refer element (\1, \k<foo> etc.)
module Regtest::Front::BackRefer
  class BackRefer
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    # Constructor
    def initialize(type, value)
      TstLog("BackRefer: #{type} #{value}")
      @type = type
      @value = value[0]
      @offset = value[1]
      @length = value[2]
      @options = @@parse_options
      @paren_obj = nil
      @relative_num = nil
    end
    
    attr_reader :offset, :length
    
    # get corresponding parenthesis object
    def get_paren(type, value)
      case type
      when :LEX_BACK_REFER    #  a pattern like \[1-9]
        if(md = value.match(/^\\(\d+)$/))
          @paren_obj = @options[:parens].get_paren(md[1].to_i)
        else
          raise "Error: Internal error, invalid back reference"
        end
      when :LEX_NAMED_REFER   # a pattern like \k<foo>, \k<1>, \k<-1>
        if(md = value.match(/^\\k[<']((\-\d+)|(\d+)|(\w+))(?:([\+\-]\d+))?[>']$/))
          if md[2]       # \k<-1>
            @paren_obj = @options[:parens].get_paren(md[1], @offset)
          elsif md[3]    # \k<1> 
            @paren_obj = @options[:parens].get_paren(md[1].to_i)
          elsif md[4]    # \k<foo> 
            @paren_obj = @options[:parens].get_paren(md[1])
          else
            raise "internal error: unexpected refer #{value}"
          end
          if md[5]
            @relative_num = md[3].to_i
          end
        else
          raise "Error: Internal error, invalid named reference"
        end
      when :LEX_NAMED_GENERATE # a pattern like \g<foo>
        if(md = value.match(/^\\g[<'](([\-\+]\d+)|(\d+)|(\w+))[>']$/))
          if md[2]       # \k<-1>
            @paren_obj = @options[:parens].get_paren(md[1], @offset)
          elsif md[3]    # \k<1> 
            @paren_obj = @options[:parens].get_paren(md[1].to_i)
          elsif md[4]    # \k<foo> 
            @paren_obj = @options[:parens].get_paren(md[1])
          else
            raise "internal error: unexpected refer #{value}"
          end
          
          if(!@paren_obj && md[1].match(/^\d+$/))
            paren_offset = md[1].to_i
            if paren_offset == 0
              @paren_obj = :WHOLE_REG_EXPRESSION
            else
              @paren_obj = @options[:parens].get_paren(paren_offset)
            end
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
    
    # transform to json format
    def json
      @paren_obj = get_paren(@type, @value)
      case @paren_obj
      when Regtest::Front::Parenthesis::Paren
        name = @paren_obj.name
        refer_name = @paren_obj.refer_name
      when :WHOLE_REG_EXPRESSION
        name = ""
        refer_name = "$$_0"
      else
        raise "Error: parenthesis #{@value} not found"
      end
      
      @@id += 1
      "{\"type\": \"#{@type}\", " +
       "\"value\": \"#{@value}\", " +
       "\"offset\": \"#{@offset}\", " +
       "\"length\": \"#{@length}\", " +
       "\"name\": \"#{name}\", " +
      " \"id\": \"c#{@@id}\", " +
       "\"refer_name\": \"#{refer_name}\", " +
       "\"relative_num\": \"#{@relative_num}\" " +
       "}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

