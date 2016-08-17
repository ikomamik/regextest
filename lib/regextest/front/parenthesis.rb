#encoding: utf-8
require 'regextest/common'
require 'regextest/front/empty'          # parser class for empty part ("", (|) etc.)

# Class for parsing parenthesis
module Regextest::Front::Parenthesis
  
  class Paren
    include Regextest::Common
    include Regextest::Front::Empty
    @@id = 0   # a class variable for generating unique name of element
    
    # Constructor
    def initialize(paren_start, element = nil, paren_end = nil)
      @options = @@parse_options
      @paren_type = paren_start[0]
      @offset = paren_start[1]
      if paren_end
        @length = (paren_end[1] - paren_start[1]) + paren_end[2]
      else
        @length = paren_start[2]
      end
      
      # delete head '(', '?', and tail ")"
      @prefix = @paren_type.sub(/^\(\??/, "")
      if @prefix.index("(") != 0
        @prefix.sub!(/\)$/, "")
      end
      
      @name = get_name(@prefix)
      @condition = nil  # set at generating json
      @refer_name = nil
      if element
        TstLog("Parenthesis: name:#{@name}, offset:#{@offset}, element:#{element}")
        @element = element
        @type_name = "LEX_PAREN"
      else
        TstLog("Parenthesis: name:#{@name}, offset:#{@offset}, element: \"\"")
        @element = TEmpty.new
        @type_name = "LEX_OPTION_PAREN"    # (?x-i) etc.
      end
      @generated_string = []
      @nest = 0
    end
    
    attr_reader :prefix, :name, :refer_name, :offset, :length

    # get name of parenthesis (if any)
    def get_name(prefix)
      if(md = prefix.match(/^[<'](\w+)[>']$/))
        md[1]
      else
        nil
      end
    end

    # get condition of parenthesis
    def get_condition(prefix)
      # puts "prefix: #{prefix}"
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
        if(Regextest::Front::Selectable::Selectable === @element)
          if(@element.candidates.size > 2)
            raise "invalid condition. 1 or 2 selectable elements"
          end
        end
      end
      
      condition_name
    end

    # set unique name for back reference
    def set_refer_name(name)
      @refer_name = name
    end

    # get generated string
    def get_value(relative_num = 0)
      # print "gen: "; pp @generated_string
      if(@generated_string.size > 0)
        @generated_string[-1]
      else
        warn "Error: refer uninitialized parenthesis"
        nil
      end
    end
    
    # set options
    def set_options(options)
      reg_options = options[:reg_options]
      TstLog("Parenthesis set_options before: #{reg_options.inspect}, prefix: #{@prefix}");
      if md = @prefix.match(/^([imxdau]*(?:\-[imx]*)?)(:)?$/)
        if md[2]
          # deep copy if (?imx: ) pattern
          cur_options = reg_options.dup
        else
          # replace option if (?imx) pattern
          cur_options = reg_options
        end
        cur_options.modify(md[1])
        TstLog("Parenthesis set_options after: #{cur_options.inspect}, new_regopt: #{md[1]}");
      else
        cur_options = reg_options
      end
      
      new_options = options.dup
      new_options[:reg_options] = cur_options

      @element.set_options(new_options)
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      @condition = get_condition(@prefix)
      condition_name = @condition.refer_name if @condition
      "{\"type\": \"#{@type_name}\"," +
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

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

