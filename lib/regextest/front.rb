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
  
    # Json option as a workaround for ruby 1.9.*
    @json_option = { max_nesting: 999 }  
    
    # scanning the string
    scanner = Regextest::Front::Scanner.new
    lex_words = scanner.scan(reg_string)
    
    # initialize management class of parentheses
    @options[:parens] = Regextest::Front::ManageParentheses.new()

    # Prepare parsers (for whole regex parser and bracket parser)
    @parser = RegextestFrontParser.new
    
    # Do parse
    @parse_result = @parser.parse(lex_words, @options)
    
    # process options
    @parse_result.set_options(options)
    
    # sort parentheses, since number of parenthesis is by offset-order (not by parsing-order)
    @options[:parens].sort
    
    @parse_result    
  end

  # Output JSON format parse result of the regex
  def get_object
    json_obj = JSON.parse(@parse_result.json, @json_option)
    parsed_object = {
      "regex"  => json_obj,
      "source" => @options[:reg_source]
    }
    TstLog("JSON param:\n" + JSON.pretty_generate(parsed_object, @json_option))
    parsed_object
  end

  # Return JSON string
  def get_json_string
    JSON.pretty_generate(get_object, @json_option)
  end

  # Return JSON of regex
  def get_json_regex
    JSON.pretty_generate(get_object["regex"], @json_option)
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
