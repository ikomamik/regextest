# encoding: utf-8
require 'regtest/common'
require 'regtest/front/repeat'

# An element (a letter or a parenthesis) with quantifier
module Regtest::Front::Repeatable
  class Repeatable
    include Regtest::Common
    include Regtest::Front::Repeat
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(value)
      TstLog("Repeatable: #{value}")
      @value = value
      @offset = value.offset
      @length = value.length
      @quant = []
    end
    
    attr_reader :offset, :length
    
    # add quantifier
    def set_quant(quant_value)
      quant = quant_value[0]
      @length += quant_value[2]
      TstLog("Repeatable quant: #{quant_value}")
      @quant.push Repeat.new(quant)
      self
    end
    
    # set options
    def set_options(options)
      TstLog("Repeatable set_options: #{options[:reg_options].inspect}"); 
      @value.set_options(options)
      self
    end
    
    # transform to json format
    def json
      json_string = ""
      @quant.each do | current |
        @@id += 1
        json_string += 
          "{\"type\": \"LEX_REPEAT\", " +
          " \"id\": \"m#{@@id}\", " +
          " \"value\": "
      end
      
      json_string += @value.json
      
      if @quant.size > 0
        work = @quant.map do | current |
          " \"offset\": #{@offset}, " +
          " \"length\": #{@length}, " +
          " \"min_repeat\": #{current.min_value}, " +
          " \"max_repeat\": #{current.max_value}, " +
          " \"reluctant\": #{(current.is_reluctant?)?'"yes"':'"no"'}, " +
          " \"possessive\": #{(current.is_possessive?)?'"yes"':'"no"'} " +
          "}"
        end
        json_string += ", " + work.join(", ")
      end
      
      json_string
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
