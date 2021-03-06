# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require "strscan"

class Regextest::Front::BracketScanner

  # A table for lexical analysis of elements
  # (Not strict analisis here.)
  LexCodeLiteral = %r!\\x[0-9A-Fa-f]{1,2}|\\[0-7]{2,3}!
  LexTable = [
    [:LEX_OCTET,
     %r!\\[0123][0-7]{2}|\\[123][0-7]! ],
    [:LEX_POSIX_CHAR_CLASS,
      %r!\[:\^?\w+:\]! ],      # First letter (?<=.) is not a character class
    [:LEX_BRACKET_START2,
      %r!\[\^! ],
    [:LEX_BRACKET_START,
      %r!\[! ],
    [:LEX_BRACKET_END,
      %r!\]! ],
    [:LEX_CODE_LITERAL,
      LexCodeLiteral ],
    [:LEX_CONTROL_LETTER,
     %r!\\c\\\\|\\C-\\\\|\\c[0-~]|\\C-[0-~]! ],
    [:LEX_META_CONTROL_LETTER,
     %r!\\M-\\C-[0-~]! ],
    [:LEX_META_LETTER,
     %r!\\M-[0-~]! ],
    # [:LEX_ESCAPED_LETTER,
    #   %r!\\[tvnrbfae #\{\}\[\]\(\)]! ],    # \b is valid within character class
    [:LEX_UNICODE,
      %r!\\u\h{4}|\\u\{\h{1,6}(?:\s+\h{1,6})*\}! ],
    [:LEX_SIMPLIFIED_CLASS,
      %r!\\[wWsSdDhH]! ],
    [:LEX_UNICODE_CLASS,
      %r!(?:\\p\{\^?|\\P\{)\w+\}! ],
    [:LEX_MINUS,
      #  %r!-(?\!\]|\z)! ], # somehow this code failed at Ruby 1.9.*
      /-(?!\]|\z)/ ],       # a letter must succeeds to minus
    [:LEX_AND_AND,
      %r!\&\&! ],
    # [:LEX_SPECIAL_LETTER,  # special letters are not valid in bracket
    #   %r!\\[RX]! ],
    [:LEX_ESCAPED_LETTER,
      %r!\\.! ],    # \b is valid within character class
    [:LEX_SPACE,
      %r!\s!m ],
    [:LEX_SIMPLE_ESCAPE,      # redundant escape \@, \", etc.
     %r!\\.! ],
    [:LEX_CHAR,
      %r!.! ],

    # Following lex word is not necessary
    #[:LEX_BACK_REFER,
    # %r!\\[1-9]\d*! ],
    #[:LEX_NAMED_REFER,
    # %r!\\k[<']\w+(?:[\+\-]\d+)?[>']! ],
    #[:LEX_ANY_LETTER,
    #  %r!\.! ],

  ]
  
  def initialize(options = nil)
    reg_options = options[:reg_options]

    @lex_table = LexTable
    whole_lex = @lex_table.map{|lex| "(?<#{lex[0]}>" + lex[1].source + ")"}.join('|')
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
        raise "bracket syntax error, offset #{offset}, \n" +
              test_string + "\n" +
              (" "*offset)+"^"
      end
    end
    results.push [false, nil]
    results
  end
  
  # method for testing
  def self.test(test_string, reg_options = 0)
    puts "String: #{test_string.inspect}"
    results = Regextest::Front::BracketScanner.new().scan(test_string)
  end
end


  # Test suite (execute when this file is specified in command line)
  if __FILE__ == $0 
    require 'kconv'
    puts "test #{__FILE__}"
    Regextest::Front::BracketScanner.test("[abc]")
    Regextest::Front::BracketScanner.test('[[:alnum:]]')
    Regextest::Front::BracketScanner.test('[[:^lower:]]')
    Regextest::Front::BracketScanner.test('[\x0a\070\n]')
    Regextest::Front::BracketScanner.test('[\w\s\1]')
    Regextest::Front::BracketScanner.test('[[ab]')
    Regextest::Front::BracketScanner.test('[)ab]')
    Regextest::Front::BracketScanner.test('[^\]ab]')
    Regextest::Front::BracketScanner.test('[\uabcd\u3030\u{4040}\u{8 4040 ffffff}]')
    Regextest::Front::BracketScanner.test('[\d&&[^47]]')   # これはダメ。
    Regextest::Front::BracketScanner.test('[\p{ALPHA}\p{^NUMBER}\P{ALPHANUM}]')
    Regextest::Front::BracketScanner.test('[ab  # comment
]', Regexp::EXTENDED)
    
  end

