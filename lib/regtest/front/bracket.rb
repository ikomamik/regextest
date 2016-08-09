# encoding: utf-8
require 'regtest/common'
require 'regtest/front/repeat'

# Select a character (bracket)
module Regtest::Front::Bracket
  class Bracket
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(value, elem)
      @value  = value[0]
      @offset = value[1]
      @length = value[2]
      if(@value.match(/^\[\^/))
        @type = false
      else
        @type = true
      end
      @element = elem
      TstLog("Bracket: value: #{value}, type: #{@type}, elem: #{elem}")
      
      # Reverse in case "[^"
      if(!@type)
        @element.reverse
      end
    end
    
    attr_reader :offset, :length
    
    # enumerate codepoints
    def enumerate
      @element.enumerate
    end
    
    # set options
    def set_options(options)
      TstLog("Bracket set_options: #{options[:reg_options].inspect}");
      @element.set_options(options)
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      "{" +
        "\"type\": \"LEX_BRACKET\",  " +
        "\"id\": \"b#{@@id}\", " +
        "\"value\": #{@element.json}, " +
        "\"offset\": #{@offset}, " +
        "\"length\": #{@length} " +
      "}"
    end
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
