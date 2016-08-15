# encoding: utf-8
require 'regtest/common'
require 'regtest/front/range'          # Range of character
require 'regtest/front/case-folding'   # case folding class
require 'regtest/regex-option'         # Options of regex
require 'regtest/front/unicode'

# character class elements
module Regtest::Front::CharClass
  class CharClass
    include Regtest::Common
    include Regtest::Front::Range
    @@id = 0   # a class variable for generating unique name of element
    @@ascii_whole_set   = nil
    @@unicode_whole_set = nil
    
    attr_reader :candidates, :offset, :length

    # Constructor
    def initialize(value)
      TstLog("CharClass: #{value}")
      @@ascii_whole_set ||= get_ascii_whole_set
      @@unicode_whole_set ||= get_unicode_whole_set
      
      
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @candidates = value
        @offset = -1 # value[0].offset
        @length = -1 # value[-1].offset + value[-1].length - value[0].offset
      when TRange
        @candidates = [value]
        @offset = -1
        @length = -1
      when String   # value is a class names joined by "|"
        class_names = value
        @candidates = []
        class_names.split("|").each do | class_name |
          work = Regtest::Front::Unicode.property(class_name) ||
            raise("Invalid Unicode class #{class_name}")
          # construct char class
          @candidates += work.map{|elem| TRange.new(elem[0], elem[1])}
        end
        @offset = -1
        @length = -1
      else
        @candidates = [value]
        @offset = value.offset
        @length = value.length
      end
      
      @is_reverse = false
      @whole_set = nil
      @other_char_classes = []
      
    end
    
    # Add a letter to candidate letters
    def add(value)
      TstLog("CharClass add: #{value}"); 
      @candidates.push value
      @length = value.offset - @offset + value.length
      self
    end
    
    # Add TRange objects
    def add_ranges(ranges)
      TstLog("CharClass add_trange: #{ranges}"); 
      @candidates += ranges
      self
    end
    
    # reverse candidate letters (valid only in a bracket)
    def reverse
      TstLog("CharClass reverse"); 
      @is_reverse = true
    end
    
    def set_reverse(options)
      TstLog("CharClass set_reverse"); 
      
      # Calc whole set of letters (depends on language environment)
      @whole_set = get_whole_set(options)

      # delete characters from whole set
      whole = @whole_set.dup
      @candidates.each do | candidate |
        whole -= candidate.enumerate
      end
      
      # reconstructing valid character set using TRange objects
      @candidates = reconstruct_candidates(whole)
      self
    end

    # Reconstruct candidate letters
    def reconstruct_candidates(code_points)
      # Consecutive code points are reconstructed into a TRange object
      new_candidates = []
      if code_points.size > 0
        range_start = range_end = code_points.shift
        while(codepoint = code_points.shift)
          if(codepoint == range_end + 1)
            range_end = codepoint
          else
            new_candidates.push TRange.new(range_start, range_end)
            range_start = range_end = codepoint
          end
        end
        new_candidates.push TRange.new(range_start, range_end)
      end
      new_candidates
    end
    
    # set other char-set (AND(&&) notation)
    def and(other_char_class)
      TstLog("CharClass and: #{other_char_class}");

      @other_char_classes.push other_char_class
      self
    end

    # AND process of candidates
    def and_process(options)
      code_points = enumerate
      @other_char_classes.each do | other_char_class |
        other_char_class.set_options(options)
        code_points &= other_char_class.enumerate
      end
      
      # reconstructing valid character set using TRange objects
      @candidates = reconstruct_candidates(code_points)
    end
    
    # Get whole code set
    def get_whole_set(options)
      reg_options = options[:reg_options]
      if reg_options.is_unicode?
        whole_set = @@unicode_whole_set
      else
        whole_set = @@ascii_whole_set
      end
      
      if reg_options.is_multiline?
        whole_set |= ["\n"]
      end
      whole_set
    end
    
    # Get whole code set of ascii
    def get_ascii_whole_set
      # require 'regtest/front/unicode'
      # same as  [ TRange.new("\x20", "\x7e") ]
      ascii_set = Regtest::Front::Unicode.enumerate("ascii")
      print_set = Regtest::Front::Unicode.enumerate("print")
      ascii_set & print_set
    end
    
    # Get whole code set of unicode
    def get_unicode_whole_set
      # require 'regtest/front/unicode'
      char_set = []
      TstConstUnicodeCharSet.split("|").each do | elem |
        char_set |= Regtest::Front::Unicode.enumerate(elem)
      end
      char_set
    end
    
    # enumerate nomimated letters
    def enumerate
      TstLog("CharClass enumerate")
      @candidates.inject([]){|result, candidate| result += candidate.enumerate}
    end
    
    # ignore process
    def ignore_process(options)
      if options[:reg_options].is_ignore?
        alternatives = []
        @candidates.each do |candidate|
          candidate.enumerate.each do | letter |
            if alter = Regtest::Front::CaseFolding.ignore_case([letter])
              alternatives.push alter[0]
            end
          end
        end
        if alternatives.size > 0
          code_points = enumerate
          alternatives.each do | alternative |
            # ignore alternative is more than two letters
            code_points.push(alternative[0]) if(alternative.size == 1)
          end
          @candidates = reconstruct_candidates(code_points)
        end
      end
    end
    
    # fixes charset using options
    def set_options(options)
      TstLog("CharClass set_options: #{options[:reg_options].inspect}")
      
      # call set_options of other bracket
      @candidates.each do |candidate|
        if candidate.respond_to?(:set_options)
          candidate.set_options(options)
        end
      end
      
      and_process(options) if @other_char_classes.size > 0

      ignore_process(options)
      
      # reverse char set
      if @is_reverse
        set_reverse(options)
      end

      self
    end
    
    # transform to json format
    def json
      #if @candidates.size > 1
        @@id += 1
        "{" +
          "\"type\": \"LEX_CHAR_CLASS\", \"id\": \"CC#{@@id}\", " +
          "\"offset\": #{@offset}, \"length\": #{@length}, " +
          "\"value\": [" + @candidates.map{|elem| elem.json}.join(",") +
        "]}"
      #else
      #  @candidates[0].json
      #end
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

