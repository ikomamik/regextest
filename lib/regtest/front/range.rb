# encoding: utf-8

require 'regtest/front/case-folding'   # case folding hash

# Consective codepoints
module Regtest::Front::Range
  class TRange
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(letter_begin, letter_end = nil)
      TstLog("TRange: #{letter_begin}-#{letter_end}")
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
      when Regtest::Front::Letter::TLetter
        eval('"' + letter.value + '"').unpack("U*")[0]
      else
        raise "Internal error. invalid letter class #{letter}"
      end
    end
    
    # enumerate
    def enumerate
      (@begin..@end).to_a
    end
    
    # transform to json format (using codepoints of Unicode)
    def json
      @@id += 1
      "{\"type\": \"LEX_RANGE\", \"id\": \"G#{@@id}\", \"begin\": #{@begin}, \"end\": #{@end}}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

