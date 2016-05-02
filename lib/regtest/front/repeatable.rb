# encoding: utf-8
require 'regtest/front/repeat'

# An element (a letter or a parenthesis) with quantifier
module Regtest::Front::Repeatable
  class Repeatable
    include Regtest::Front::Repeat
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(value)
      TstLog("Repeatable: #{value}")
      @value = value
      @offset = value.offset
      @length = value.length
      @quant = nil
    end
    
    attr_reader :offset, :length
    
    # add quantifier
    def set_quant(quant_value)
      quant = quant_value[0]
      @length += quant_value[2]
      TstLog("Repeatable quant: #{quant_value}")
      if !@quant
        @quant = Repeat.new(quant)
      else
        raise "Error: syntax error, duplicate quantifier #{quant}"
      end
      self
    end
    
    # transform to json format
    def json
      if(@quant)
        @@id += 1
        "{\"type\": \"LEX_REPEAT\", " +
        " \"id\": \"m#{@@id}\", " +
        " \"value\": #{@value.json}, " +
        " \"offset\": #{@offset}, " +
        " \"length\": #{@length}, " +
        " \"min_repeat\": #{@quant.min_value}, " +
        " \"max_repeat\": #{@quant.max_value}}"
      else
        @value.json
      end
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
