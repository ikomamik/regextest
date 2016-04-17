# encoding: utf-8

require "strscan"
require "pp"

class Regtest::Front::BracketScanner

  # 正規表現文字の素語解析用のテーブル(ここで厳密に解析せず
  # ちょっとしたミスは、構文解析側でエラー出力するようにする）
  LexCodeLiteral = %r!\\x[0-9A-Fa-f]{1,2}|\\[0-7]{2,3}!
  LexTable = [
    [:LEX_POSIX_CHAR_CLASS,
      %r!\[:\^?\w+:\]! ],      # 文字列先頭の場合(?<=.)は、文字クラスでは無い
    [:LEX_BRACKET_START2,
      %r!\[\^! ],
    [:LEX_BRACKET_START,
      %r!\[! ],
    [:LEX_BRACKET_END,
      %r!\]! ],
    [:LEX_CODE_LITERAL,
      LexCodeLiteral ],
    [:LEX_CONTROL_LETTER,
      %r!\\c[a-z]|\\C-[a-z]! ],
    [:LEX_META_LETTER,
      %r!\\M-(?:\\w|#{LexCodeLiteral.source})! ],
    # [:LEX_ESCAPED_LETTER,
    #   %r!\\[tvnrbfae #\{\}\[\]\(\)]! ],    # 文字クラスでは\bは有効
    [:LEX_UNICODE,
      %r!\\u\h{4}|\\u\{\h{1,6}(?:\s+\h{1,6})*\}! ],
    [:LEX_SIMPLIFIED_CLASS,
      %r!\\[wWsSdDhH]! ],
    [:LEX_UNICODE_CLASS,
      %r!(?:\\p\{\^?|\\P\{)\w+\}! ],
    [:LEX_MINUS,
      %r!-! ],
    [:LEX_AND_AND,
      %r!\&\&! ],
    [:LEX_SPECIAL_LETTER,
      %r!\\[RX]! ],
    [:LEX_EXTENDED_COMMENT,
      %r!\#.*?(?:\n|$)! ],
    [:LEX_ESCAPED_LETTER,
      %r!\\.! ],    # 文字クラスでは\bは有効
    [:LEX_SPACE,
      %r!\s!m ],
    [:LEX_CHAR,
      %r!.! ],

    # 以下は不要として削除
    #[:LEX_BACK_REFER,
    # %r!\\[1-9]\d*! ],
    #[:LEX_NAMED_REFER,
    # %r!\\k[<']\w+(?:[\+\-]\d+)?[>']! ],
    #[:LEX_ANY_LETTER,
    #  %r!\.! ],

  ]
  
  def initialize(options = nil)
    reg_options = options[:reg_options]

    if( reg_options.is_extended? )
      @lex_table = LexTable
    else
      @lex_table = LexTable.delete_if{|elem| elem[0] == :LEX_EXTENDED_COMMENT}
    end
    whole_lex = @lex_table.map{|lex| "(?<#{lex[0]}>" + lex[1].source + ")"}.join('|')
    puts whole_lex
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
  
  # テスト用のメソッド
  def self.test(test_string, reg_options = 0)
    puts "String: #{test_string.inspect}"
    results = Regtest::Front::BracketScanner.new().scan(test_string)
    pp results
  end
end


  # テストスィート（このファイルがコマンド指定されたときだけ実行）
  if __FILE__ == $0 
    require 'kconv'
    puts "test #{__FILE__}"
    Regtest::Front::BracketScanner.test("[abc]")
    Regtest::Front::BracketScanner.test('[[:alnum:]]')
    Regtest::Front::BracketScanner.test('[[:^lower:]]')
    Regtest::Front::BracketScanner.test('[\x0a\070\n]')
    Regtest::Front::BracketScanner.test('[\w\s\1]')
    Regtest::Front::BracketScanner.test('[[ab]')
    Regtest::Front::BracketScanner.test('[)ab]')
    Regtest::Front::BracketScanner.test('[^\]ab]')
    Regtest::Front::BracketScanner.test('[\uabcd\u3030\u{4040}\u{8 4040 ffffff}]')
    Regtest::Front::BracketScanner.test('[\d&&[^47]]')   # これはダメ。
    Regtest::Front::BracketScanner.test('[\p{ALPHA}\p{^NUMBER}\P{ALPHANUM}]')
    Regtest::Front::BracketScanner.test('[ab  # comment
]', Regexp::EXTENDED)
    
  end



