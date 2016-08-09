# encoding: utf-8

class Regtest::Back; end
require 'regtest/common'
require 'regtest/back/main'

# Backend class of regtest. Generate matched string
class Regtest::Back
  include Regtest::Common
  
  # Constructor
  def initialize(json_obj)
    @reg_source = @@parse_options[:reg_source]
    @json_obj = json_obj
    
    # COMMENTED OUT at present
    # make a hash to manage names and corresponding objects
    # @name_hash = make_name_hash(@json_obj, {})
    # get test cases (commented at present)
    # @test_info = Regtest::Back::TestCase.new(@json_obj, @name_hash)
    
    # default max recursion is 8.
    @max_nest = (ENV['TST_MAX_RECURSION'])?(ENV['TST_MAX_RECURSION'].to_i):8
  end
  
  # A public method that generates string to match the regexp
  def generate
    generate_obj = Regtest::Back::Main.new(@json_obj, @max_nest)
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

