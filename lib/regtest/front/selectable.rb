# encoding: utf-8

require 'regtest/regex-option'         # Options of regex

# selectable elements
module Regtest::Front::Selectable
  class Selectable
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    attr_reader :nominates, :offset, :length

    # Constructor
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @nominates = value
        @offset = value[0].offset
        @length = value[-1].offset + value[-1].length - value[0].offset
      else
        @nominates = [value]
        @offset = value.offset
        @length = value.length
      end
    end
    
    # add selectable sequence
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @nominates.push value
      @length = value.offset - @offset + value.length
      self
    end

    # set options
    def set_options(options)
      TstLog("Selectlable set_options: #{options[:reg_options].inspect}"); 
      reg_options = (options)?options[:reg_options]:nil
      @nominates.each do | nominate |
        nominate.set_options(options)
      end
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      "{" +
        "\"type\": \"LEX_SELECT\", \"id\": \"S#{@@id}\", " +
        "\"offset\": #{@offset}, \"length\": #{@length}, " +
        "\"value\": [" + @nominates.map{|elem| elem.json}.join(",") +
      "]}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

