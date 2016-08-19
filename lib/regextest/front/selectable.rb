# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/regex-option'         # Options of regex

# selectable elements
module Regextest::Front::Selectable
  class Selectable
    include Regextest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    attr_reader :candidates, :offset, :length

    # Constructor
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @candidates = value
        @offset = value[0].offset
        @length = value[-1].offset + value[-1].length - value[0].offset
      else
        @candidates = [value]
        @offset = value.offset
        @length = value.length
      end
    end
    
    # add selectable sequence
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @candidates.push value
      @length = value.offset - @offset + value.length
      self
    end

    # set options
    def set_options(options)
      TstLog("Selectlable set_options: #{options[:reg_options].inspect}"); 
      reg_options = (options)?options[:reg_options]:nil
      @candidates.each do | candidate |
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
        "\"value\": [" + @candidates.map{|elem| elem.json}.join(",") +
      "]}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

