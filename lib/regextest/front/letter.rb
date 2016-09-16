# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/front/char-class'     # character class element
require 'regextest/front/range'          # range of character point
require 'regextest/regex-option'

# A letter
module Regextest::Front::Letter
  class TLetter
    include Regextest::Common
    include Regextest::Front::CharClass
    include Regextest::Front::Range
    @@id = 0   # a class variable for generating unique name of element
    @@unicode_ranges = {}
      
    # Constructor
    def initialize(type, val)
      TstLog("TLetter: type:#{type}, value:#{val}")
      @options = nil
      @data_type = type
      @value = val[0] || ""
      @offset = val[1] || -1
      @length = val[2] || 0
      @obj = nil
    end
    
    attr_reader :offset, :length, :value
    
    # generate character(s) corresponding type of the character
    def set_attr(type, val)
      case type
      when :LEX_CHAR, :LEX_SPACE
        @data_type = :LEX_CHAR
        @obj = CharClass.new([ TRange.new(val)])
      when :LEX_SIMPLE_ESCAPE
        @data_type = :LEX_CHAR
        @obj = CharClass.new([ TRange.new(val[1..1])])
      when :LEX_CODE_LITERAL, :LEX_ESCAPED_LETTER, :LEX_UNICODE, :LEX_OCTET
        @data_type = :LEX_CHAR
        @obj = CharClass.new([ TRange.new(eval('"'+ val + '"'))])   # convert using ruby's eval
      when :LEX_CONTROL_LETTER, :LEX_META_LETTER
        @data_type = :LEX_CHAR
        @obj = generate_control_letter(val, type)
      when :LEX_BRACKET
        @obj = Regextest::Front::Bracket.new(val)
      when :LEX_SIMPLIFIED_CLASS
        @obj = generate_simplified_class(val)
      when :LEX_POSIX_CHAR_CLASS
        @obj = generate_char_class(val)
      when :LEX_UNICODE_CLASS
        @obj = generate_unicode_char(val)
      when :LEX_ANY_LETTER
        @obj = generate_any_char(val)
      when :LEX_SPECIAL_LETTER
        @obj = generate_special_char(val)
      when :LEX_AND_AND
        raise "Internal error: enexpected LEX_AND_AND"
        @obj = CharClass.new([TRange.new(val)])
      else
        raise "Error: internal error, type:#{type} not implemented"
      end
    end
    
    # generate control letter \c-x, \m-x
    def generate_control_letter(val, type)
      suffix = val[-1..-1]
      codepoint = suffix.unpack("U*")[0]
      case type
      when :LEX_CONTROL_LETTER
        if    ('0'..'?').include?(suffix)
          result = codepoint - 0x20
        elsif ('@'..'_').include?(suffix)
          result = codepoint - 0x40
        elsif ('`'..'~').include?(suffix)
          result = codepoint - 0x60
        else
          raise "Internal error: invalid control letter (#{val})"
        end
      when :LEX_META_LETTER
        result = codepoint + 0x80
        pp [result].pack("U*")
      else
        raise "Internal error: invalid type #{type}"
      end
      @obj = CharClass.new([ TRange.new([result].pack("U*"))])
    end
    
    # generate whole set of letters (depends on option)
    def generate_any_char(val)
      if @options[:reg_options].is_unicode?
        obj = CharClass.new(TstConstUnicodeCharSet)
      else
        obj = CharClass.new( [ TRange.new("\x20", "\x7e") ] )
      end
      
      if( @options[:reg_options].is_multiline? )
          obj.add_ranges( [ TRange.new("\n") ] )
      end
      obj
    end
    
    # generate special character class
    def generate_special_char(val)
      @data_type = :LEX_CHAR
      obj = nil
      case val
      when "\\R"
        if @options[:reg_options].is_unicode?
          # BUG: "\x0a\x0d" must be supported!
          obj = CharClass.new(
                  [ TRange.new("\x0a", "\x0d"), TRange.new("\u{85}"),
                    TRange.new("\u{2028}", "\u{2029}") ]
                )
        else
          # BUG: "\x0a\x0d" must be supported!
          obj = CharClass.new(
                  [ TRange.new("\x0a", "\x0d") ]
                )
        end
      when "\\X"
        if @options[:reg_options].is_unicode?
          # BUG: (?>\P{M}\p{M}*)
          obj = CharClass.new("M")
          obj.set_reverse(@options)
        else
          obj = CharClass.new(
                  [ TRange.new("\x20", "\x7e"), TRange.new("\n") ]
                )
        end
      else
        raise "Error: internal error, invalid special char: #{val}"
      end
      obj
    end
    
    # generate simplified character class
    def generate_simplified_class(val)
      obj = nil
      case val
      when "\\w"
        if @options[:reg_options].is_unicode?
          obj = CharClass.new("Letter|Mark|Number|Connector_Punctuation")
        else
          obj = CharClass.new(
                  [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                    TRange.new('0', '9'), TRange.new('_') ]
                )
        end
      when "\\W"
        obj = CharClass.new(
                [ TRange.new("\x20", "\x2f"), TRange.new("\x3a", "\x40"),
                  TRange.new("\x5b", "\x5e"), TRange.new("\x60"),
                  TRange.new("\x7b", "\x7e") ]
              )
      when "\\d"
        if @options[:reg_options].is_unicode?
          #obj = CharClass.new([ TRange.new('0', '9'),  TRange.new('０', '９')])
          obj = CharClass.new("Decimal_Number")
        else
          obj = CharClass.new(
                   [ TRange.new('0', '9') ]
                 )
        end
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
        ascii_ranges = [ TRange.new(' '), TRange.new("\x9", "\xd") ]
        if @options[:reg_options].is_unicode?
          obj = CharClass.new("Line_Separator|Paragraph_Separator|Space_Separator")
          obj.add_ranges(ascii_ranges + [ TRange.new("\u{85}") ])
        else
          obj = CharClass.new(ascii_ranges)
        end
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
    
    # generate Unicode class (ie. \p{...} | \P{...})
    def generate_unicode_char(val, type)
      if(md = val.match(/(p|P)\{(\^?)(\w+)\}/))
        class_name = md[3].downcase
        reverse = (md[2] && md[2]=="^")?true:false
        
        obj = CharClass.new(class_name, type)
      else
        raise "Internal error, inconsistent Unicode class #{val}"
      end
      
      # ￥P{^...} is equivalent to \p{...}
      if((md[1] == "p" && !reverse) || (md[1] == "P" && reverse))
        obj
      else      # \P{}  or \p{^}
        obj.set_reverse(@options)
      end
    end
    
    # generate POSIX character class (ie. [[:alpha:]], etc.)
    def generate_char_class(val)
      if(md = val.match(/^\[\:(\^)?(\w+)\:\]$/))
        reverse = (md[1] && md[1]=="^")?true:false
        class_name = md[2]
      else
        raise "internal error, invalid POSIX class name(#{val})"
      end
      
      obj = nil
      if @options[:reg_options].is_unicode?
        obj = CharClass.new(class_name)
      else
        case class_name
        when 'alnum'
          obj = CharClass.new(
                  [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                    TRange.new('0', '9') ]
                )
        when 'alpha'
          obj = CharClass.new(
                  [ TRange.new('a', 'z'), TRange.new('A', 'Z') ]
                )
        when 'cntrl'
          obj = CharClass.new(
                  [ TRange.new("\x00", "\x1f"), TRange.new("\x7f") ]
                )
        when 'lower'
          obj = CharClass.new(
                  [ TRange.new('a', 'z') ]
                )
        when 'print'
          obj = CharClass.new(
                  [ TRange.new("\x20", "\x7e") ]
                )
        when 'space'
          obj = CharClass.new(
                  [ TRange.new(' '), TRange.new("\n"), TRange.new("\r"), 
                    TRange.new("\t"), TRange.new("\f"), TRange.new("\v") ]
                )
        when 'digit'
          obj = CharClass.new(
                  [ TRange.new('0', '9') ]
                )
        when 'upper'
          obj = CharClass.new(
                  [ TRange.new('A', 'Z') ]
                )
        when 'blank'
          obj = CharClass.new(
                  [ TRange.new(' '), TRange.new("\t")  ]
                )
        when 'graph'
          obj = CharClass.new(
                  [ TRange.new("\x21", "\x7e") ]
                )
        when 'punct'
          obj = CharClass.new(
                  [ TRange.new("\x21", "\x23"), TRange.new("\x25", "\x2a"), 
                    TRange.new("\x2c", "\x2f"), TRange.new("\x3a", "\x3b"),
                    TRange.new("\x3f", "\x40"), TRange.new("\x5b", "\x5d"),
                    TRange.new("\x5f"), TRange.new("\x7b"), TRange.new("\x7d") ]
                )
        when 'xdigit'
          obj = CharClass.new(
                  [ TRange.new('a', 'f'), TRange.new('A', 'F'),
                    TRange.new('0', '9') ]
                )
        when 'word'
          obj = CharClass.new(
                  [ TRange.new('a', 'z'), TRange.new('A', 'Z'),
                    TRange.new('0', '9'), TRange.new('_') ]
                )
        else
          raise "Error: Invalid character class #{val}"
        end
      end
      
      if reverse
        obj.set_reverse(@options)
      end
      
      obj
    end
    
    # enumerate codepoints
    def enumerate
      @obj.enumerate
    end
    
    # set options
    def set_options(options)
      TstLog("Letter set_options: #{options[:reg_options].inspect}")
      @options = options
      set_attr(@data_type, @value)
      @obj.set_options(options)
      self
    end
    
    # transform to json format
    def json
      @@id += 1
      charset = @options[:reg_options].charset
      "{" +
        "\"type\": \"#{@data_type}\", \"id\": \"L#{@@id}\", \"value\": #{@obj.json}, " +
         "\"offset\": #{@offset}, \"length\": #{@length}, " +
         "\"charset\": \"#{charset}\"" +
      "}"
    end
  end
end


# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

