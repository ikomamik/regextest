# encoding: utf-8

# This routine defines Regtest class
class Regtest; end

# Required classes
require 'regtest/version'
require 'regtest/common'
require 'regtest/front'
require 'regtest/front/parser'
require 'regtest/regex-option'
require 'regtest/back'
require 'regtest/regexp'

class Regtest
  include Regtest::Common

  # constants
  TstConstRetryMax =  (ENV['TST_MAX_RETRY'])?(ENV['TST_MAX_RETRY'].to_i):5
  
  # Constructer
  def initialize(param, options = {})
    @@parse_options = options
    @@parse_options[:reg_options] = Regtest::RegexOption.new
    @reg_string = nil
    @reg_exp = nil
    set_regex(param)

    # Prepare parsers (for whole regex and bracket)
    @parser = RegtestFrontParser.new
    
    # Do parse
    @obj = @parser.parse(@reg_string, @@parse_options)
    
    # To json
    @json_obj = get_json_obj(@obj)
    
    # Prepare back-end process. (use generate method for generating string)
    @back_end = Regtest::Back.new(@json_obj)
    
    @result = nil
    @reason = nil
  end
  
  attr_reader :reason
  
  # Covert to source string if necessary
  def set_regex(param)
    case param
    when String
      if param.match(/^\/.*\/[imx]*$/)
        @reg_exp = eval(param)
        @reg_string = @reg_exp.source
      else
        new_param = check_builtin(param)
        @reg_string = new_param
        @reg_exp = /#{@reg_string}/
      end
      @@parse_options[:reg_source] = @reg_string
    when Regexp
      @reg_exp = param
      @@parse_options[:reg_options].set(@reg_exp.options)   # inner regex options have priorty
      @reg_string = @reg_exp.source
      
      # following codes must be changed later
      if @reg_string.match(/^\(\?\w*x/)
        @@parse_options[:reg_options].modify("x")
      end
    else
      raise "Error: string or regular expression required"
    end
  end

  # genetate string to be matched with specified regular expression
  def generate
    TstConstRetryMax.times do 
      @result = @back_end.generate
      if @result
        @result = verify    # returns a match-object
      else
        TstLog "NG: Failed to generate"
        @reason = :failed_to_generate
        @result = nil
      end
      break if @result
    end
    @result
  end
  
  # add built-in functions if any
  def check_builtin(param)
    builtin_functions = {}
    param.scan(/\\g[\<\'](_\w+_)[\>\']/) do | func_name |
      builtin_functions[func_name[0]] = true
    end
    if builtin_functions.keys.size > 0
      require 'regtest/front/builtin-functions'
      functions = Regtest::Front::BuiltinFunctions.new
      builtin_functions.keys.each do | func_name |
        if func_string = functions.find_func(func_name)
          param = param + func_string
        else
          raise "invalid built-in function name (#{func_name})"
        end
      end
    end
    param
  end
  
  # Verifies the result
  def verify
    return nil unless(@result)
    result_string = @result.pre_match + @result.match + @result.post_match
    if(md = @reg_exp.match(result_string))
      if(md.pre_match  != @result.pre_match || 
         md.to_a[0]    != @result.match ||
         md.post_match != @result.post_match)
        @reason = :invalid_match_string
        TstLog "WARN: Invalid matched string"
        TstLog "  proc: #{md.pre_match.inspect}  <-->  #{@result.pre_match.inspect}"
        TstLog "  body: #{md.to_a[0].inspect}  <-->  #{@result.match.inspect}"
        TstLog "  succ: #{md.post_match.inspect}  <-->  #{@result.post_match.inspect}"
      end
      md
    else
      @reason = { rc: :not_matched, string: result_string}
      raise "failed to generate. Not matched regex(#{@reg_string}) string(#{result_string.inspect})"
    end
    # @result = @back_end.generate
  end
  
  # Output JSON format parse result of the regex
  def get_json_obj(result = @obj)
    require "json"
    json_obj = JSON.load(result.json)
    puts JSON.pretty_generate(json_obj)
    json_obj
  end
end

# Log
def TstLog(msg)
  if(!defined? Rails)  # not output debug message when rails env (even if development mode)
    warn msg
  end
end

# Test suite
if __FILE__ == $0
  def md_print(md)
    "#{md.pre_match.inspect[1..-2]}\e[36m#{md.to_a[0].inspect[1..-2]}\e[0m#{md.post_match.inspect[1..-2]}"
  end
  
  begin
    
    regex = ARGV[0] || $<
    if(regex == "reg")
      regex = /ab # comment
      [a-z]{5,10}
      cd	   /ix
    end
    if(regex == "reg2")
      regex = %r(
      (?<name> [a-zA-Z_:]+ ){0}
      (?<stag> < \g<name>  > ){0}
      (?<content> ||\w+|\w+|\w+ (\g<element> | \w+)* ){0}
      (?<etag> </ \k<name+1> >){0}
      (?<element> \g<stag> \g<content>* \g<etag> ){0}
      \g<element>
      )x
    end
    
    begin
      if ARGV[1]
        reg = eval "/#{regex}/#{ARGV[1]}"
      else
        reg = regex
      end
    rescue SyntaxError => ex
      warn "Ruby Regexp: Syntax error: " + ex.message
      reg = regex
    end
    
    prog = Regtest.new(reg)
    10.times do
      if(md = prog.generate)
        puts "*>\t" + md_print(md)     # md.string.inspect
      else
        puts "Failed to generate regex(#{reg})"
      end
    end
  
  rescue RegexpError => ex
    $stderr.puts "Parse error. #{ex.message}"
    exit(1)

  rescue RuntimeError => ex
    # Error process. put error message and exit
    $stderr.puts ex.message
    exit(1)
  end

end

