# encoding: utf-8

require 'regtest/front/range'          # Range of character
require 'regtest/regex-option'         # Options of regex

# character class elements
module Regtest::Front::CharClass
  class CharClass
    include Regtest::Common
    include Regtest::Front::Range
    @@id = 0   # a class variable for generating unique name of element
    
    attr_reader :nominates, :offset, :length

    # Constructor
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @nominates = value
        @offset = -1 # value[0].offset
        @length = -1 # value[-1].offset + value[-1].length - value[0].offset
      when TRange
        @nominates = [value]
        @offset = -1
        @length = -1
      else
        @nominates = [value]
        @offset = value.offset
        @length = value.length
      end
      
      # Calc whole set of letters (depends on language environment)
      @whole_set = get_whole_set
    end
    
    # Add a letter to nominate letters
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @nominates.push value
      @length = value.offset - @offset + value.length
      self
    end
    
    # reverse nominate letters (valid only in a bracket)
    def reverse
      TstLog("Selectlable reverse"); 

      # delete characters from whole set
      whole = @whole_set.dup
      @nominates.each do | nominate |
        whole -= nominate.enumerate
      end
      
      # reconstructing valid character set using TRange objects
      @nominates = reconstruct_nominates(whole)
    end

    # Reconstruct nominate letters
    def reconstruct_nominates(char_set)
      # Convert each letter to corresponding code point
      code_points = char_set.map{|letter| letter.unpack("U*")[0]}
      
      # Consecutive code points are reconstructed into a TRange object
      new_nominates = []
      if code_points.size > 0
        range_start = range_end = code_points.shift
        while(codepoint = code_points.shift)
          if(codepoint == range_end + 1)
            range_end = codepoint
          else
            new_nominates.push TRange.new([range_start].pack("U*"), [range_end].pack("U*"))
            range_start = range_end = codepoint
          end
        end
        new_nominates.push TRange.new([range_start].pack("U*"), [range_end].pack("U*"))
      end
      new_nominates
    end
    
    # AND process of nominates
    def and(other_char_class)
      TstLog("Selectlable and: #{other_char_class}");

      char_set = enumerate & other_char_class.enumerate
      
      # reconstructing valid character set using TRange objects
      @nominates = reconstruct_nominates(char_set)
      self
    end
    
    # Get whole code set
    def get_whole_set
      if( @reg_options.is_multiline? )
        work = [ TRange.new("\x20", "\x7e"),  TRange.new("\n")]
      else
        work = [ TRange.new("\x20", "\x7e") ]
      end
      work.inject([]){|result,elem| result |= elem.enumerate}
    end
    
    # generating a set of letters
    def generate2
      offsets = (0 ... @nominates.size).to_a.shuffle
      result = nil
      offsets.each do | offset |
        result = @nominates[offset].generate
        break if(result)
      end
      result
    end
    
    # enumerate nomimated letters
    def enumerate
      @nominates.inject([]){|result, nominate| result += nominate.enumerate}
    end
    
    # transform to json format
    def json
      #if @nominates.size > 1
        @@id += 1
        "{" +
          "\"type\": \"LEX_CHAR_CLASS\", \"id\": \"CC#{@@id}\", " +
          "\"offset\": #{@offset}, \"length\": #{@length}, " +
          "\"value\": [" + @nominates.map{|elem| elem.json}.join(",") +
        "]}"
      #else
      #  @nominates[0].json
      #end
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

