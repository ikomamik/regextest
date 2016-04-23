# encoding: utf-8

require 'regtest/front/char-class'     # character class element
require 'regtest/front/range'          # range of character point
require 'regtest/regex-option'

# A letter
module Regtest::Front::Letter
  class TLetter
    include Regtest::Common
    include Regtest::Front::CharClass
    include Regtest::Front::Range
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
    
    # 文字のタイプによって生成値または生成オブジェクトを設定
    def set_attr(type, val)
      case type
      when :LEX_CHAR, :LEX_SPACE, :LEX_AND_AND
        @obj = val
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
    
    # 全ての文字生成
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
    
    # 簡易指定の値生成
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
    
    # Unicodeクラス指定時の値生成
    def generate_unicode_char(val)
      # Unicode関連のモジュールは動的に読み込み(性能アップのため）
      require 'regtest/front/unicode'        # Unicodeのレンジ
      TLetter.include Regtest::Front::ParseUnicode
      
      if(md = val.match(/\{(\w+)\}/))
        class_name = md[1]
        if !@@unicode_ranges[class_name]
          @@unicode_ranges[class_name] = Unicode.property(class_name) ||
            raise("Invalid Unicode class #{class_name} in #{val}")
        end
      end
      @@unicode_ranges[class_name]
    end
    
    # POSIX文字クラス指定時の値生成
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
    
    # 文字の列挙
    def enumerate
      if String === @obj
        [ @obj ]
      else
        @obj.enumerate
      end
    end
    
    # 結果のリセット
    def reset
      if String === @obj
        # 何もしない
      else
        @obj.reset
      end
    end
    
    # JSONへの変換
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

