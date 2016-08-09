# encoding: utf-8

# This routine defines front-end of Regtest
class Regtest::Front; end
require 'regtest/common'
require 'regtest/front/scanner'        # scanner class (for splitting the string)
require 'regtest/front/parser'         # parser class (using racc)
require 'regtest/front/manage-parentheses'   # management class of parentheses

# Front end processes
class Regtest::Front
  def initialize(reg_string, options)
    @options = options
  
    # scanning the string
    scanner = Regtest::Front::Scanner.new
    lex_words = scanner.scan(reg_string)
    
    # initialize management class of parentheses
    @options[:parens] = Regtest::Front::ManageParentheses.new()

    # Prepare parsers (for whole regex parser and bracket parser)
    @parser = RegtestFrontParser.new
    
    # Do parse
    @obj = @parser.parse(lex_words, @options)
    
    # process options
    @obj.set_options(options)
    
    # sort parentheses, since number of parenthesis is by offset-order (not by parsing-order)
    @options[:parens].sort
    
    @obj    
  end

  # Output JSON format parse result of the regex
  def get_json_obj(result = @obj)
    require "json"
    json_obj = JSON.load(result.json)
    # puts JSON.pretty_generate(json_obj)
    json_obj
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
