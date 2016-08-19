# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

class Regextest::Back; end
require 'regextest/common'
require 'regextest/back/main'

# Backend class of regextest. Generate matched string
class Regextest::Back
  include Regextest::Common
  
  # Constructor
  def initialize(json_obj)
    @reg_source = @@parse_options[:reg_source]
    @json_obj = json_obj
    
    # COMMENTED OUT at present
    # make a hash to manage names and corresponding objects
    # @name_hash = make_name_hash(@json_obj, {})
    # get test cases (commented at present)
    # @test_info = Regextest::Back::TestCase.new(@json_obj, @name_hash)
    
    # default max recursion is 8.
    @max_nest = TstConstRecursionMax
  end
  
  # A public method that generates string to match the regexp
  def generate
    generate_obj = Regextest::Back::Main.new(@json_obj, @max_nest)
    generate_obj.generate
  end
  
  # make a hash to manage names and corresponding objects
  def make_name_hash(target, name_hash)
    # register id (and refer-name in case of parenthesis)
    raise "Internal error: found duplicate id #{target["id"]}" if target["id"] && name_hash[target["id"]]
    name_hash[target["id"]] = target
    name_hash[target["refer_name"]] = target if(target["type"] == "LEX_PAREN")
    
    # recursively register names
    if(target["value"])
      if( Array === target["value"])
        target["value"].each{|child| make_name_hash(child, name_hash)}
      else
        make_name_hash(target["value"], name_hash)
      end
    end
    name_hash
  end
  
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0

end

