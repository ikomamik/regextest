# encoding: utf-8
require 'regtest/common'
require 'regtest/regex-option'         # Options of regex

# selectable elements
module Regtest::Front::Selectable
  class Selectable
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    attr_reader :candidate, :offset, :length

    # Constructor
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @candidate = value
        @offset = value[0].offset
        @length = value[-1].offset + value[-1].length - value[0].offset
      else
        @candidate = [value]
        @offset = value.offset
        @length = value.length
      end
    end
    
    # add selectable sequence
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @candidate.push value
      @length = value.offset - @offset + value.length
      self
    end

    # set options
    def set_options(options)
      TstLog("Selectlable set_options: #{options[:reg_options].inspect}"); 
      reg_options = (options)?options[:reg_options]:nil
      @candidate.each do | candidate |
        candidate.set_options(options)
      end
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      "{" +
        "\"type\": \"LEX_SELECT\", \"id\": \"S#{@@id}\", " +
        "\"offset\": #{@offset}, \"length\": #{@length}, " +
        "\"value\": [" + @candidate.map{|elem| elem.json}.join(",") +
      "]}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

