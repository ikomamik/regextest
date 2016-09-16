# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require "strscan"
require 'regextest/common'
require "pp"

class Regextest::Front::Scanner
  include Regextest::Common

  # A table for lexical analysis of elements
  # (Not strict analisis here.)
  LexCodeLiteral = %r!\\x[0-9A-Fa-f]{1,2}|\\[0-7]{2,3}!
  LexTable = [
    [:LEX_OCTET,
     %r!\\[0123][0-7]{2}|\\[123][0-7]! ],
    [:LEX_BACK_REFER,
     %r!\\[1-9]\d*! ],
    [:LEX_CODE_LITERAL,
     LexCodeLiteral ],
    [:LEX_NAMED_REFER,
     %r!(?u:\\k[<'](?:\-?\d+|\w+)(?:[\+\-]\d+)?[>'])! ],
    [:LEX_NAMED_GENERATE,
     %r!(?u:\\g[<'][\+\-]?\w+[>'])! ],
    [:LEX_CONTROL_LETTER,
     %r!\\c[a-zA-Z]|\\C-[a-zA-Z]|\\c\\\\|\\C-\\\\! ],
    [:LEX_META_LETTER,
     %r!\\M-(?:[a-zA-Z]|\\C-[a-zA-Z])! ],
    [:LEX_ESCAPED_LETTER,
     %r!\\[tvnrfae #\{\}\[\]\(\)]! ],   # \b is an anchor out of bracket
    [:LEX_UNICODE,
     %r!\\u\h{4}|\\u\{\h{1,6}(?:\s+\h{1,6})*\}! ],
    # [:LEX_POSIX_CHAR_CLASS,           # invalid out of bracket
    #   %r!\[:\w+:\]! ],
    [:LEX_SIMPLIFIED_CLASS,
     %r!\\[wWsSdDhH]! ],
    [:LEX_UNICODE_CLASS,
     %r!\\[pP]\{\^?\w+\}! ],
    [:LEX_QUANTIFIER,
     %r![\?\*\+][\?\+]?|\{\d+(?:,\d*)?\}\??|\{,\d+\}\??! ],
    [:LEX_COMMENT,
     %r!\(\?\#(?:\\\)|[^\)])*\)! ],
    [:LEX_OPTION_PAREN_1,
     %r!\(\?(?=\w*x)[imxdau]+(?:\-[im]*)?\)! ],              # (?x-im)
    [:LEX_OPTION_PAREN_2,
     %r!\(\?[imxdau]*(?:\-(?=\w*x)[imx]+)?\)! ],             # (?im-x)
    [:LEX_PAREN_START_EX1,
     %r!\(\?(?=\w*x)[imxdau]+(?:\-[im]*)?(?::|(?=\)))! ],    # (?x-im: ... )
    [:LEX_PAREN_START_EX2,
     %r!\(\?[imxdau]*(?:\-(?=\w*x)[imx]+)?(?::|(?=\)))! ],   # (?im-x: ... )
    [:LEX_PAREN_START,
     %r!(?u:\(\?<\w+>|
            \(\?'\w+'|
            \(\?\(\d+\)|
            \(\?\(<\w+>\)|
            \(\?\('\w+'\)|
            \(\?[imdau]*(?:\-[im]*)?(?::|(?=\)))|    # expressions independent of "x"
            \(\?\<[\=\!]|
            \(\?.|    # for better error message
            \(
        )
       !x ],
    [:LEX_PAREN_END,
     %r!\)! ],
    [:LEX_BRACKET,     # considering nested bracket
     # %r!(?<bs>\[(?:\[:\^?\w+:\]|\\\]|\\.|[^\]\[]|\g<bs>)+\])! ],
     %r!(?<bs>
        \[\^?\]?       # first part [, [^, [], [^] are possible
          (?:|                # body part
             \[:\^?\w+:\]|
             \\\]|
             \\.|
             # \&\&\]|   # &&] is valid... however not matched ']'. why?
             [^\]\[]|
             \g<bs>
          )+
        \])
       !x ],
    [:LEX_OR,
     %r!\|! ],
    [:LEX_ANC_LINE_BEGIN,
     %r!\^! ],
    [:LEX_ANC_LINE_END,
     %r!\$! ],
    [:LEX_ANC_WORD_BOUND,
     %r!\\b! ],
    [:LEX_ANC_WORD_UNBOUND,
     %r!\\B! ],
    [:LEX_ANC_STRING_BEGIN,
     %r!\\A! ],
    [:LEX_ANC_STRING_END,
     %r!\\z! ],
    [:LEX_ANC_STRING_END2,
     %r!\\Z! ],
    [:LEX_ANC_LOOK_BEHIND2,   # included in Ruby but not in Onigmo
     %r!\\K! ],
    [:LEX_ANC_MATCH_START,
     %r!\\G! ],
    [:LEX_SPECIAL_LETTER,
     %r!\\[RX]! ],
    [:LEX_SHARP,
     %r!\#! ],
    [:LEX_ANY_LETTER,
     %r!\.! ],
    # [:LEX_EXTENDED_COMMENT,  # commented out since there is dynamic syntax change using (?x: ...)
    #  %r!\#.*?(?:\n|$)! ],
    [:LEX_NEW_LINE,
     %r!\n!m ],
    [:LEX_SPACE,
     %r!\s!m ],
    # [:LEX_ERROR,  # commented out since /]/ or /foo # [/x is valid notation
    #  %r![\[\]]! ],
    [:LEX_SIMPLE_ESCAPE,      # redundant escape \@, \", etc.
     %r!\\.! ],
    # [:LEX_REGOPT_LETTER,      # imxdau
    #  %r![imxdau]! ],
    [:LEX_CHAR,
     %r!.! ],
  ]
  
  def initialize
    @lex_table = LexTable.dup
    whole_lex = @lex_table.map{|lex| "(?<#{lex[0]}>" + lex[1].source + ")"}.join('|')
    # puts whole_lex
    @reg = /^#{whole_lex}/mx
  end
    
  # 
  def scan(test_string)
    results = []
    match_string = test_string
    match_offset = 0
    while (md = @reg.match(match_string))
      scan_offset = @lex_table.index{|elem| md[elem[0]]}
      name = @lex_table[scan_offset][0]
      if(name != :LEX_ERROR)
        lex_word = md[name]
        match_length = md.end(0)
        results.push [name, [lex_word, match_offset, match_length]]
        match_string = md.post_match
        match_offset += match_length
      else
        offset = test_string.index(match_string)
        raise "Regexp syntax error, offset #{offset}, \n" + test_string + "\n" + (" "*offset) + "^"
      end
    end
    results.push [false, nil]
    TstLog("Scanned elements:\n#{results}")
    results
  end
  
  # method for testing
  def self.test(test_string, reg_options = nil)
    puts "String: #{test_string.inspect}"
    results = Regextest::Front::Scanner.new().scan(test_string)
    pp results
  end
end


# Test suite (execute when this file is specified in command line)
  if __FILE__ == $0 
    require 'kconv'
    puts "test #{__FILE__}"
    Regextest::Front::Scanner.test("(aa(bb))")
    Regextest::Front::Scanner.test('\x0a\070\n')
    Regextest::Front::Scanner.test('(\w+)\s\1')
    Regextest::Front::Scanner.test('\A(?<a>|.|(?:(?<b>.)\g<a>\k<b+0>))\z')
    Regextest::Front::Scanner.test("(?<abcd>foo|(bar)*|(hoge|boke))")
    Regextest::Front::Scanner.test("^.+?ab{3}c{3,}d{4,5}e{,5}f??")
    Regextest::Front::Scanner.test("([abcd]aa(bb))")
    Regextest::Front::Scanner.test('([[ab][)ab][^\]ab])')
    Regextest::Front::Scanner.test('\uabcd\u3030\u{4040}\u{8 4040 ffffff}')
    Regextest::Front::Scanner.test('[\d&&[^47]]')   # これはダメ。
    Regextest::Front::Scanner.test('\p{ALPHA}\p{^NUMBER}\P{ALPHANUM}')
    Regextest::Front::Scanner.test('[[:alnum:][:^lower:]]')
    Regextest::Front::Scanner.test('(?# comment)')
    Regextest::Front::Scanner.test('ab  #
', Regexp::EXTENDED)

    # BUG
    Regextest::Front::Scanner.test('aa(?)bb')     # must be error
    
  end



