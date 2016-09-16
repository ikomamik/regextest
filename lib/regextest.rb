# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

# This routine defines Regextest class
class Regextest; end

# Required classes
require 'regextest/version'
require 'regextest/common'
require 'regextest/front'
require 'regextest/regex-option'
require 'regextest/back'
require 'regextest/regexp'
require 'timeout'

class Regextest
  include Regextest::Common

  # exceptions
  class RegextestError             < RuntimeError; end
  class RegextestFailedToGenerate  < RuntimeError; end
  class RegextestTimeout           < RuntimeError; end

  # Constructor of Regextest class
  # @param [String|Regexp] regex regular expression object (or string)
  # @param [Hash] options parameters for generating
  # @option options [Regextest::RegexOption] :reg_options Regex option parameter
  # @option options [Fixnum] :seed seed for randomization
  # @option options [TrueClass] :verification specify true (or not speficy) to verify generated string using ruby Regexp.
  # @option options [FalseClass] :verification specify false if skip to verify generated string.
  # @return [Regextest] constructed object
  def initialize(regex, options = {})
    @@parse_options = options
    @@parse_options[:reg_options] ||= Regextest::RegexOption.new
    @verification = (options && options[:verification] == false)?false:true
    @reg_string = nil
    @reg_exp = nil
    
    # Set seed for randomizing
    @seed = set_seed_for_randomizing(@@parse_options[:seed])

    # Covert to source string if necessary
    set_regex(regex)

    # Parse string
    @front_end = Regextest::Front.new(@reg_string, @@parse_options)
    
    # Prepare back-end process. (use generate method for generating string)
    @back_end = Regextest::Back.new(@front_end)
    
    @result = nil
    @reason = nil
  end
  
  # @!attribute [r] reason
  #   Reason if failed to generate
  #   @return [hash] return reasons if failed to generate
  #   @return [nil] return nil unless error
  attr_reader :reason
  
  # @!attribute [r] seed
  #   Seed for randomization
  #   @return [Fixnum] return seed for randomization
  #   @return [nil] return nil if no seed provided
  attr_reader :seed
  
  # Genetate string matched with specified regular expression
  # @return [MatchData] if matched and verified.
  # @return [String] if matched without verification (i.e. return unverified matched string).
  # @return [nil] nil if failed to generate
  # @raise [RuntimeError] if something wrong...
  # @raise [Regextest::RegextestTimeout] if detected timeout while verification. Option 'verification: false' may be workaround.
  def generate
    TstConstRetryMax.times do | retry_count |
    
      # generate string
      reset_random_called
      @result = @back_end.generate(retry_count)
      if !@result
        TstLog "NG: Failed to generate"
        @reason = :failed_to_generate
        if !is_random?
          raise(RegextestError, "It is impossible to generate sample string of #{@reg_string}.")
        end
        next
      end

      result_string = @result.pre_match + @result.match + @result.post_match
      
      # verify generated string
      if @verification
        @result = verify(result_string)    # returns a match-object
        if !@result
          TstLog "NG: Failed to verify"
          @reason = :failed_to_verify
          next
        end
        # break if @result is verified
      else
        @result = result_string            # returns a string
      end
      break
    end
    
    if !@result
      raise(RegextestFailedToGenerate, "Regextest failed to generate sample string of #{@reg_string}.")
    end
    @result
  end
  
  # Get parsed result as JSON string
  # @return [String] parsed result as JSON string
  def to_json
    @front_end.get_json_string
  end
  #---------------#
  private
  
  # Set seed for randomizing
  def set_seed_for_randomizing(seed)
    if seed
      raise "Invalid seed (#{seed}: #{seed.class}) specified" if !(Integer === seed)
      srand seed
      seed
    else
      srand   # return preset seed
    end
  end
  
  # Covert to source string if necessary
  def set_regex(param)
    case param
    when String
      if md = param.match(/^\/(.*)\/([imx]*)$/)
        @reg_exp = eval(param)
        @reg_string = @reg_exp.source
      else
        new_param = check_builtin(param)
        @reg_string = new_param
        @reg_exp = /#{@reg_string}/
      end
    when Regexp
      @reg_exp = param
      @@parse_options[:reg_options].set(@reg_exp.options)   # inner regex options have priorty
      @reg_string = @@parse_options[:reg_options].prefix_reg + @reg_exp.source
    else
      raise "Error: string or regular expression required"
    end
    @@parse_options[:reg_source] = @reg_string
  end

  # add built-in functions if any
  def check_builtin(param)
    builtin_functions = {}
    param.scan(/\\g[\<\'](_\w+_)[\>\']/) do | func_name |
      builtin_functions[func_name[0]] = true
    end
    if builtin_functions.keys.size > 0
      require 'regextest/front/builtin-functions'
      functions = Regextest::Front::BuiltinFunctions.new
      builtin_functions.keys.each do | func_name |
        if func_string = functions.find_func(func_name)
          param = param + func_string
        else
          raise "invalid built-in function name (#{func_name})"
        end
      end
    end
    param
  end
  
  # Verifies the result
  def verify(result_string)
    md = nil
    begin
      timeout(TstConstTimeout){
        md = @reg_exp.match(result_string)
      }
    rescue Timeout::Error => ex
      raise(RegextestTimeout,
            "Timeout(#{TstConstTimeout} sec) detected while verifying string(#{result_string}) matched with regex(#{@reg_exp}).")
    end
    
    if(md)
      # matched string sometime differs from expected one...
      if(md.pre_match  != @result.pre_match || 
         md.to_a[0]    != @result.match ||
         md.post_match != @result.post_match)
        @reason = :invalid_match_string
        TstLog "WARN: Invalid matched string, expected <--> actual"
        TstLog "  proc: #{md.pre_match.inspect}  <-->  #{@result.pre_match.inspect}"
        TstLog "  body: #{md.to_a[0].inspect}  <-->  #{@result.match.inspect}"
        TstLog "  succ: #{md.post_match.inspect}  <-->  #{@result.post_match.inspect}"
      end
    else
      @reason = { rc: :not_matched, string: result_string}
      raise("failed to generate. Not matched regex(#{@reg_string}) string(#{result_string.inspect})")
    end
    md
  end
end

# Test program
if __FILE__ == $0
  # ruby regextest.rb 'regular-expression'    =>  regular-expression
  # ruby regextest.rb '[ab]'                  =>  a
  include Regextest::Common

  begin
    
    regex = ARGV[0] || $<
    
    if(regex == "reg")
      regex = /(?ix:ab # comment
      [a-z]{5,10}
      cd	   )/
    end
    
    if(regex == "reg2")
      regex = %r((?x:
      (?<name> [a-zA-Z_:]+ ){0}
      (?<stag> < \g<name>  > ){0}
      (?<content> \w+ (\g<element> | \w+)* ){0}
      (?<etag> </ \k<name+1> >){0}
      (?<element> \g<stag> \g<content>* \g<etag> ){0}
      \g<element>
      ))x
    end
    
    begin
      if ARGV[1]
        reg = eval "/#{regex}/#{ARGV[1]}"
      else
        reg = regex
      end
    rescue SyntaxError => ex
      warn "Ruby Regexp: Syntax error: " + ex.message
      reg = regex
    end
    
    prog = Regextest.new(reg)
    
    10.times do
      if(md = prog.generate)
        puts "  " + TstMdPrint(md)     # md.string.inspect
      else
        puts "Failed to generate regex(#{reg})"
      end
    end
  
  rescue RegexpError => ex
    $stderr.puts "Parse error. #{ex.message}"
    exit(1)

  rescue Regextest::RegextestTimeout => ex
    $stderr.puts ex.message
    exit(1)
    
  rescue RuntimeError => ex
    # Error process. put error message and exit
    $stderr.puts ex.message
    exit(1)
  end

end

