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

class Regtest
  include Regtest::Common
  
  # Constructer
  def initialize(param, options = {})
    @@parse_options = options
    @@parse_options[:reg_options] = Regtest::RegexOption.new
    @regex = get_regex(param)
    @@parse_options[:reg_source] = @regex
        
    # Prepare parsers (for whole regex and bracket)
    @parser = RegtestFrontParser.new
    
    # Do parse
    @obj = @parser.parse(@regex, @@parse_options)
    
    # To json
    @json_obj = get_json_obj(@obj)
    
    # Prepare back-end process. (use generate method for generating string)
    @back_end = Regtest::Back.new(@json_obj)
    
    @result = nil
    @reason = nil
  end
  
  attr_reader :reason
  
  # Covert to source string if necessary
  def get_regex(param)
    case param
    when String
      reg_string = param
    when Regexp
      @@parse_options[:reg_options].set(param.options)   # inner regex options have priorty
      reg_string = param.source
    else
      raise "Error: string or regular expression required"
    end
    reg_string
  end

  # genetate string to be matched with specified regular expression
  def generate
    @result = @back_end.generate
    if @result
      verify    # returns a match-object
    else
      puts "NG: Failed to generate"
      @reason = :failed_to_generate
      nil
    end
  end
  
  # Verifies the result
  def verify
    return nil unless(@result)
    result_string = @result.pre_match + @result.match + @result.post_match
    reg = /#{@regex}/
    if(md = reg.match(result_string))
      if md.pre_match  == @result.pre_match && 
         md.to_a[0]    == @result.match &&
         md.post_match == @result.post_match
         md
      else
       @reason = :invalid_match
       puts "NG: Invalid matched string"
        puts "  proc: #{md.pre_match.inspect}  <-->  #{@result.pre_match.inspect}"
        puts "  body: #{md.to_a[0].inspect}  <-->  #{@result.match.inspect}"
        puts "  succ: #{md.post_match.inspect}  <-->  #{@result.post_match.inspect}"
        nil
      end
    else
      @reason = { rc: :not_matched, string: result_string}
      puts "NG: not matched. regex(#{@regex}) string(#{result_string.inspect})"
      nil
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
  warn msg
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
      reg = eval "/#{regex}/#{ARGV[1]}"
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
    # エラー時の処理。エラーメッセージを出力して終了
    $stderr.puts ex.message
    exit(1)
  end

end

