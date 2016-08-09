# encoding: utf-8
require 'regtest/common'

# Empty part
module Regtest::Front::Empty
  class TEmpty
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize
      TstLog("Empty: ")
      @offset = -1
      @length = 0
    end
    
    attr_reader :offset, :length
    
    # set options
    def set_options(options)
      TstLog("Empty set_options: #{options[:reg_options].inspect}");
      # do nothing
      self
    end
    
    # generate json format
    def json
      @@id += 1
        "{" +
           "\"type\": \"LEX_EMPTY\", \"id\": \"E#{@@id}\", \"value\": \"\", " +
           "\"offset\": #{@offset}, \"length\": #{@length}" +
        "}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

