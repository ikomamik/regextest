# encoding: utf-8
require 'regtest/common'
require 'regtest/regex-option'

# Anchor class
module Regtest::Front::Anchor
  class Anchor
    include Regtest::Common
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
      
    # Constructor
    def initialize(type, val)
      TstLog("Anchor: value:#{val}")
      @type = type
      @value = val[0] || ""
      @offset = val[1] || -1
      @length = val[2] || 0
    end
    
    attr_reader :offset, :length
    
    # set options
    def set_options(options)
      TstLog("Anchor set_options: #{options[:reg_options].inspect}");
    end
    
    # transform to json format
    def json
      @@id += 1
      "{" +
         "\"type\": \"#{@type}\", \"id\": \"A#{@@id}\", \"value\": \"#{@value}\", " +
         "\"offset\": #{@offset}, \"length\": #{@length}" +
      "}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

