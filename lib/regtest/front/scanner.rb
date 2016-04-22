# encoding: utf-8

require "strscan"
require "pp"

class Regtest::Front::Scanner
  # 正規表現文字の素語解析用のテーブル(ここで厳密に解析せず
  # ちょっとしたミスは、構文解析側でエラー出力するようにする）
  LexCodeLiteral = %r!\\x[0-9A-Fa-f]{1,2}|\\[0-7]{2,3}!
  LexTable = [
    [:LEX_BACK_REFER,
     %r!\\[1-9]\d*! ],
    [:LEX_CODE_LITERAL,
     LexCodeLiteral ],
    [:LEX_NAMED_REFER,
     %r!\\k[<']\w+(?:[\+\-]\d+)?[>']! ],
    [:LEX_NAMED_GENERATE,
     %r!\\g[<']\w+[>']! ],
    [:LEX_CONTROL_LETTER,
     %r!\\c[a-z]|\\C-[a-z]! ],
    [:LEX_META_LETTER,
     %r!\\M-(?:\\w|#{LexCodeLiteral.source})! ],
    [:LEX_ESCAPED_LETTER,
     %r!\\[tvnrfae #\{\}\[\]\(\)]! ],      # \bは文字クラス外ではアンカー
    [:LEX_UNICODE,
     %r!\\u\h{4}|\\u\{\h{1,6}(?:\s+\h{1,6})*\}! ],
    # [:LEX_POSIX_CHAR_CLASS,    # 文字クラス以外では無効
    #   %r!\[:\w+:\]! ],
    [:LEX_SIMPLIFIED_CLASS,
     %r!\\[wWsSdDhH]! ],
    [:LEX_UNICODE_CLASS,
     %r!(?:\\p\{\^?|\\P\{)\w+\}! ],
    [:LEX_QUANTIFIER,
     %r![\?\*\+][\?\+]?|\{\d+(?:,\d*)?\}\??|\{,\d+\}\??! ],
    [:LEX_COMMENT,
     %r!\(\?\#(?:\\\)|[^\)])*\)! ],
    # [:LEX_OPTION_PAREN,
    #  %r!\(\?[imxdau]*(?:\-[imx]+)?\)! ],
    [:LEX_PAREN_START,
     %r!\(\?<\w+>|
        \(\?'\w+'|
        \(\?\(\d+\)|
        \(\?\(<\w+>\)|
        \(\?\('\w+'\)|
        \(\?[imxdau]*(?:\-[imx]+)?(?::|(?=\)))|
        \(\?\<[\=\!]|
        \(\?.|
        \(
       !x ],
    [:LEX_PAREN_END,
     %r!\)! ],
    [:LEX_BRACKET,     # condidering nested bracket
     %r!(?<bs>\[(?:\[:\^?\w+:\]|\\\]|[^\]\[]|\g<bs>)+\])! ],
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
    [:LEX_ANY_LETTER,
     %r!\.! ],
    [:LEX_EXTENDED_COMMENT,
     %r!\#.*?(?:\n|$)! ],
    [:LEX_SPACE,
     %r!\s!m ],
    [:LEX_ERROR,
     %r![\{\}\[\]]! ],
    [:LEX_CHAR,
     %r!.! ],
  ]
  
  def initialize(options = nil)
    reg_options = (options)?options[:reg_options]:nil

    if( reg_options && reg_options.is_extended? )
      @lex_table = LexTable
    else
      @lex_table = LexTable.delete_if{|elem| elem[0] == :LEX_EXTENDED_COMMENT}
    end
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
    results
  end
  
  # テスト用のメソッド
  def self.test(test_string, reg_options = nil)
    puts "String: #{test_string.inspect}"
    results = Regtest::Front::Scanner.new().scan(test_string)
    pp results
  end
end


  # テストスィート（このファイルがコマンド指定されたときだけ実行）
  if __FILE__ == $0 
    require 'kconv'
    puts "test #{__FILE__}"
    Regtest::Front::Scanner.test("(aa(bb))")
    Regtest::Front::Scanner.test('\x0a\070\n')
    Regtest::Front::Scanner.test('(\w+)\s\1')
    Regtest::Front::Scanner.test('\A(?<a>|.|(?:(?<b>.)\g<a>\k<b+0>))\z')
    Regtest::Front::Scanner.test("(?<abcd>foo|(bar)*|(hoge|boke))")
    Regtest::Front::Scanner.test("^.+?ab{3}c{3,}d{4,5}e{,5}f??")
    Regtest::Front::Scanner.test("([abcd]aa(bb))")
    Regtest::Front::Scanner.test('([[ab][)ab][^\]ab])')
    Regtest::Front::Scanner.test('\uabcd\u3030\u{4040}\u{8 4040 ffffff}')
    Regtest::Front::Scanner.test('[\d&&[^47]]')   # これはダメ。
    Regtest::Front::Scanner.test('\p{ALPHA}\p{^NUMBER}\P{ALPHANUM}')
    Regtest::Front::Scanner.test('[[:alnum:][:^lower:]]')
    Regtest::Front::Scanner.test('(?# comment)')
    Regtest::Front::Scanner.test('ab  #
', Regexp::EXTENDED)

    # BUG
    Regtest::Front::Scanner.test('aa(?)bb')     # must be error
    
  end



