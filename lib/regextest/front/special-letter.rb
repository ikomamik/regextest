# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/front'

# Parse special letter element (\R / \X etc.)
module Regextest::Front::SpecialLetter
  class SpecialLetter
    include Regextest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    # Constructor
    def initialize(value)
      TstLog("SpecialLetter: #{value}")
      @value = value[0]
      @offset = value[1]
      @length = value[2]
      @options = @@parse_options
      @string = nil
      @obj = nil
    end
    
    attr_reader :offset, :length
    
    # set string
    def set_string(options)
      reg_options = options[:reg_options]
      case @value
      when "\\R"
        if reg_options.is_unicode?
          '(?:\x0d\x0a|[\x0a-\x0c\u{85}\u{2028}\u{2029}]|\x0d(?!\x0a))'
        else
          '(?:\x0d\x0a|\x0d(?!\x0a)|[\x0a-\x0c])'
        end
      when "\\X"
        # Unicode mode is not implemented yet
        '(?m:.)'
      else
        raise "Internal error. Invalid special letter(#{value})"
      end
    end
    
    # set options
    def set_options(options)
      TstLog("SpecialLetter set_options: #{options[:reg_options].inspect}")
      @string = set_string(options)
      @obj = Regextest::Front.new(@string, options)
      self
    end
    
    # transform to json format
    def json
      @obj.get_json_regex
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

