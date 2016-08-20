# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

# This routine defines front-end of Regextest
class Regextest::Front; end
require 'regextest/common'
require 'regextest/front/scanner'        # scanner class (for splitting the string)
require 'regextest/front/parser'         # parser class (using racc)
require 'regextest/front/manage-parentheses'   # management class of parentheses
require "json"

# Front end processes
class Regextest::Front
  include Regextest::Common
  def initialize(reg_string, options)
    @options = options
  
    # scanning the string
    scanner = Regextest::Front::Scanner.new
    lex_words = scanner.scan(reg_string)
    
    # initialize management class of parentheses
    @options[:parens] = Regextest::Front::ManageParentheses.new()

    # Prepare parsers (for whole regex parser and bracket parser)
    @parser = RegextestFrontParser.new
    
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
    option = { max_nesting: 999}  # work around for ruby 1.9.*
    json_obj = JSON.parse(result.json, option)
    TstLog("JSON param:\n" + JSON.pretty_generate(json_obj, option))
    json_obj
  end

  # Return JSON string
  def get_json_string(result = @obj)
    json_obj = get_json_obj(result)
    option = { max_nesting: 999}  # work around for ruby 1.9.*
    JSON.pretty_generate(json_obj, option)
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
