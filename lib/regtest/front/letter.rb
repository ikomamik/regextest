# encoding: utf-8

require 'regtest/front/char-class'     # character class element
require 'regtest/front/range'          # range of character point
require 'regtest/regex-option'
require 'regtest/front/unicode'        # Unicodeのレンジ

# A letter
module Regtest::Front::Letter
  class TLetter
    include Regtest::Common
    include Regtest::Front::CharClass
    include Regtest::Front::Range
    include Regtest::Front::Unicode   # 
    @@id = 0   # a class variable for generating unique name of element
    @@unicode_ranges = {}
      
    # Constructor
    def initialize(type, val)
      TstLog("TLetter: type:#{type}, value:#{val}")
      @reg_options = @@parse_options[:reg_options]
      @data_type = type
      @value = val[0] || ""
      @offset = val[1] || -1
      @length = val[2] || 0
      @obj = nil
      @options = @@parse_options
      set_attr(type, @value)
    end
    
    attr_reader :offset, :length
    
    # generate character(s) corresponding type of the character
    def set_attr(type, val)
      case type
      when :LEX_CHAR, :LEX_SPACE, :LEX_AND_AND
        @obj = val
      when :LEX_SIMPLE_ESCAPE
        @obj = val[1..1]
      when :LEX_CONTROL_LETTER, :LEX_META_LETTER
        @obj = eval('"'+ val + '"')   # convert using ruby's eval
      when :LEX_BRACKET
        require 'regtest/front/bracket'
        @obj = Regtest::Front::Bracket.new(val)
      when :LEX_CODE_LITERAL, :LEX_ESCAPED_LETTER, :LEX_UNICODE
        @obj = eval('"'+val+'"')
      when :LEX_SIMPLIFIED_CLASS
        @obj = generate_simplified_class(val)
      when :LEX_POSIX_CHAR_CLASS
        @obj = generate_char_class(val)
      when :LEX_UNICODE_CLASS
        @obj = generate_unicode_char(val)
      when :LEX_ANY_LETTER
        @obj = generate_any_char(val)
      else
        raise "Error: internal error, type:#{type} not implemented"
      end
    end
    
    # generate whole set of letters (depends on option)
    def generate_any_char(val)
      if( @reg_options.is_multiline? )
        @obj = CharClass.new(
                 [ TRange.new("\x20", "\x7e"),  TRange.new("\n")]
               )
      else
        @obj = CharClass.new(
                 [ TRange.new("\x20", "\x7e") ]
               )
      end
    end
    
    # generate simplified character class
    def generate_simplified_class(val)
      obj = nil
      case val
      when "\\w"
        obj = CharClass.new(
                [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                  TRange.new('0', '9'), TRange.new('_') ]
              )
      when "\\W"
        obj = CharClass.new(
                [ TRange.new("\x20", "\x2f"), TRange.new("\x3a", "\x40"),
                  TRange.new("\x5b", "\x5e"), TRange.new("\x60"),
                  TRange.new("\x7b", "\x7e") ]
              )
      when "\\d"
        obj = CharClass.new(
                [ TRange.new('0', '9') ]
              )
      when "\\D"
        obj = CharClass.new(
                [ TRange.new("\x20", "\x2f"), TRange.new("\x3a", "\x7e") ]
              )
      when "\\h"
        obj = CharClass.new(
                [ TRange.new('0', '9') , TRange.new('a', 'f'), TRange.new('A', 'F')]
              )
      when "\\H"
        obj = CharClass.new(
                [ TRange.new("\x20", "\x2f"), TRange.new("\x3a", "\x40"),
                  TRange.new("\x47", "\x60"), TRange.new("\x67", "\x7e")]
              )
      when "\\s"
        obj = CharClass.new(
                [ TRange.new(' '), TRange.new("\x9"), TRange.new("\xa"), 
                  TRange.new("\xc"), TRange.new("\xd") ]
              )
      when "\\S"
        obj = CharClass.new(
                [ TRange.new("\x21", "\x7e") ]
              )
      when "\\n", "\\r", "\\t", "\\f", "\\a", "\\e", "\\v"
        obj = CharClass.new(
                [ TRange.new(eval("\""+ string + "\"")) ]
              )
      when "\\b", "\\z", "\\A", "\\B", "\\G", "\\Z"
        warn "Ignored unsupported escape char #{val}."
      when "\\c", "\\x", "\\C", "\\M"
        raise "Error: Unsupported escape char #{string}"
      else
        raise "Error: Invalid simplifiled class #{val}"
      end
      obj
    end
    
    # generate Unicode class (ie. \p{...})
    def generate_unicode_char(val)
      # Dynamic loading of Unicode regarding modules (for better performance).
      # commented out since this code not executed at ruby 2.0.0
      #require 'regtest/front/unicode'        # Unicodeのレンジ
      #TLetter.include Regtest::Front::Unicode
      
      if(md = val.match(/\{(\w+)\}/))
        class_name = md[1].downcase
        if !@@unicode_ranges[class_name]
          @@unicode_ranges[class_name] = Unicode.property(class_name) ||
            raise("Invalid Unicode class #{class_name} in #{val}")
        end
      end
      @@unicode_ranges[class_name]
    end
    
    # generate POSIX character class (ie. [[:alpha:]], etc.)
    def generate_char_class(val)
      obj = nil
      case val
      when '[:alnum:]'
        obj = CharClass.new(
                [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                  TRange.new('0', '9') ]
              )
      when '[:cntrl:]'
        obj = CharClass.new(
                [ TRange.new("\x00", "\x1f"), TRange.new("\x7f") ]
              )
      when '[:lower:]'
        obj = CharClass.new(
                [ TRange.new('a', 'z') ]
              )
      when '[:space:]'
        obj = CharClass.new(
                [ TRange.new(' '), TRange.new("\n"), TRange.new("\r"), 
                  TRange.new("\t"), TRange.new("\f"), TRange.new("\v") ]
              )
      when '[:alpha:]'
        obj = CharClass.new(
                [ TRange.new('a', 'z'), TRange.new('A', 'Z') ]
              )
      when '[:digit:]'
        obj = CharClass.new(
                [ TRange.new('0', '9') ]
              )
      when '[:print:]'
        obj = CharClass.new(
                [ TRange.new("\x20", "\x7e") ]
              )
      when '[:upper:]'
        obj = CharClass.new(
                [ TRange.new('A', 'Z') ]
              )
      when '[:blank:]'
        obj = CharClass.new(
                [ TRange.new(' '), TRange.new("\t")  ]
              )
      when '[:graph:]'
        obj = CharClass.new(
                [ TRange.new("\x21", "\x7e") ]
              )
      when '[:punct:]'
        obj = CharClass.new(
                [ TRange.new("\x21", "\x2f"), TRange.new("\x3a", "\x40"),
                  TRange.new("\x5b", "\x60"), TRange.new("\x7b", "\x7e") ]
              )
      when '[:xdigit:]'
        obj = CharClass.new(
                [ TRange.new('a', 'f'), TRange.new('A', 'F'),
                  TRange.new('0', '9') ]
              )
      when '[:word:]'
        obj = CharClass.new(
                [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                  TRange.new('0', '9'), TRange.new('_') ]
              )
      else
        raise "Error: Invalid character class #{val}"
      end
      obj
    end
    
    # 文字列の生成
    def generate
      if String === @obj
        @obj
      else
        @obj.generate
      end
    end
    
    # set options
    def set_options(options)
      TstLog("Letter set_options: #{options[:reg_options].inspect}")
      case @obj
      when String
        if options[:reg_options].is_ignore?
          if alters = Regtest::Front::CaseFolding.ignore_case([@obj])
            @obj = CharClass.new( [ TRange.new(@obj) ] )
            alters.each{|alter| @obj.add alter}
          end
        end
      else
        @obj.set_options(options)
      end
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      if String === @obj
        "{" +
           "\"type\": \"LEX_CHAR\", \"id\": \"L#{@@id}\", \"value\": #{@obj.inspect}, " +
           "\"offset\": #{@offset}, \"length\": #{@length}" +
        "}"
      else
        "{" +
          "\"type\": \"#{@data_type}\", \"id\": \"L#{@@id}\", \"value\": #{@obj.json}, " +
           "\"offset\": #{@offset}, \"length\": #{@length}" +
        "}"
      end
    end
  end
end


# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

