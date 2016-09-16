# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/front/case-folding'   # case folding hash

# Consective codepoints
module Regextest::Front::Range
  class TRange
    include Regextest::Common
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(letter_begin, letter_end = nil)
      TstLog("TRange: #{letter_begin}-#{letter_end}")
      @options = nil
      @begin = parse_letter(letter_begin)
      if letter_end 
        @end = parse_letter(letter_end)
      else
        @end = @begin
      end

      @offset = -1  # not used in this class
      @length = -1  # not used in this class
    end
    
    attr_reader :offset, :length
    
    # parse letter
    def parse_letter(letter)
      case letter
      when String
        letter.unpack("U*")[0]
      when Integer
        letter
      when Regextest::Front::Letter::TLetter
        eval('"' + letter.value + '"').unpack("U*")[0]
      else
        raise "Internal error. invalid letter class #{letter}"
      end
    end
    
    # enumerate
    def enumerate
      (@begin..@end).to_a
    end
    
    # set options
    def set_options(options)
      TstLog("Range set_options: #{options[:reg_options].inspect}")
      @options = options
    end
    
    # transform to json format (using codepoints of Unicode)
    def json
      @@id += 1
      if @options
        charset = @options[:reg_options].charset
      else
        charset = "d"
      end
      "{" +
        "\"type\": \"LEX_RANGE\", " +
        "\"id\": \"G#{@@id}\", " +
        "\"begin\": #{@begin}, " +
        "\"end\": #{@end}, " +
        "\"charset\": \"#{charset}\"" +
      "}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

