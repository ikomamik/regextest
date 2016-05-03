# encoding: utf-8
require 'regtest/front/repeat'

# Select a character (bracket)
module Regtest::Front::Bracket
  class Bracket
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(value, elem)
      @value = value[0]
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
    
    # 文字の列挙
    def enumerate
      @element.enumerate
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
