# encoding: utf-8

class RegtestFrontParser
options no_result_var
rule
  # regular expression
  reg_exp: reg_sel
  
  # selectable elements
  reg_sel:
           {TEmpty.new}
         | reg_seq
           {Selectable.new(val[0])}
         | reg_sel LEX_OR reg_seq
           {val[0].add(val[2])}
         | reg_sel LEX_OR
           {val[0].add(TEmpty.new)}
         | LEX_OR reg_sel
           {sel = Selectable.new(TEmpty.new); sel.add(val[1]); sel}

  # sequence of elements
  reg_seq: reg_rep
           {Sequence.new(val[0])}
         | reg_seq reg_rep
           {val[0].add(val[1])}
           
  # repeatable elements
  reg_rep: reg_elm
           {Repeatable.new(val[0])}
         | reg_rep LEX_QUANTIFIER
           {val[0].set_quant(val[1])}

  # element (a letter or selectable element in parentheses)
  reg_elm: reg_let
           {val[0]}
         | LEX_PAREN_START reg_sel LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}
         | LEX_PAREN_START_EX1 reg_sel_ex LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}
         | LEX_PAREN_START_EX2 reg_sel LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}

  # letter
  reg_let: LEX_CHAR               {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_BACK_REFER         {BackRefer.new(:LEX_BACK_REFER,   val[0])}
         | LEX_CODE_LITERAL       {TLetter.new(:LEX_CODE_LITERAL,   val[0])}
         | LEX_NAMED_REFER        {BackRefer.new(:LEX_NAMED_REFER,  val[0])}
         | LEX_NAMED_GENERATE     {BackRefer.new(:LEX_NAMED_GENERATE, val[0])}
         | LEX_CONTROL_LETTER     {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_META_LETTER        {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_ESCAPED_LETTER     {TLetter.new(:LEX_ESCAPED_LETTER, val[0])}
         | LEX_UNICODE            {TLetter.new(:LEX_UNICODE,        val[0])}
         | LEX_SIMPLIFIED_CLASS   {TLetter.new(:LEX_SIMPLIFIED_CLASS, val[0])}
         | LEX_UNICODE_CLASS      {TLetter.new(:LEX_UNICODE_CLASS,  val[0])}
         | LEX_BRACKET            {@bracket_parser.parse(val[0], @options)}   # using another parser
         | LEX_ANC_LINE_BEGIN     {Anchor.new(:LEX_ANC_LINE_BEGIN,  val[0])}
         | LEX_ANC_LINE_END       {Anchor.new(:LEX_ANC_LINE_END,    val[0])}
         | LEX_ANC_WORD_BOUND     {Anchor.new(:LEX_ANC_WORD_BOUND,  val[0])}
         | LEX_ANC_WORD_UNBOUND   {Anchor.new(:LEX_ANC_WORD_UNBOUND, val[0])}
         | LEX_ANC_STRING_BEGIN   {Anchor.new(:LEX_ANC_STRING_BEGIN, val[0])}
         | LEX_ANC_STRING_END     {Anchor.new(:LEX_ANC_STRING_END,  val[0])}
         | LEX_ANC_STRING_END2    {Anchor.new(:LEX_ANC_STRING_END2, val[0])}
         | LEX_ANC_LOOK_BEHIND2   {Anchor.new(:LEX_ANC_LOOK_BEHIND2, val[0])}
         | LEX_ANC_MATCH_START    {Anchor.new(:LEX_ANC_MATCH_START, val[0])}
         | LEX_SPECIAL_LETTER     {TLetter.new(:LEX_SPECIAL_LETTER, val[0])}
         | LEX_MINUS              {TLetter.new(:LEX_CHAR,           val[0])}  # no special meaning at basic mode
         | LEX_AND_AND            {TLetter.new(:LEX_AND_AND,        val[0])}
         | LEX_SPACE              {TLetter.new(:LEX_SPACE,          val[0])}
         | LEX_SIMPLE_ESCAPE      {TLetter.new(:LEX_SIMPLE_ESCAPE,  val[0])}
         | LEX_SHARP              {TLetter.new(:LEX_CHAR,           val[0])}  # no special meaning at basic mode
         | LEX_NEW_LINE           {TLetter.new(:LEX_CHAR,           val[0])}  # no special meaning at basic mode
         | LEX_ANY_LETTER         {TLetter.new(:LEX_ANY_LETTER,     val[0])}

  # EXTENDED MODE
  # selectable elements
  reg_sel_ex:
           {TEmpty.new}
         | reg_seq_ex
           {Selectable.new(val[0])}
         | reg_sel_ex LEX_OR reg_seq_ex
           {val[0].add(val[2])}
         | reg_sel_ex LEX_OR
           {val[0].add(TEmpty.new)}
         | LEX_OR reg_sel_ex
           {sel = Selectable.new(TEmpty.new); sel.add(val[1]); sel}

  # sequence of elements
  reg_seq_ex: reg_rep_ex
           {Sequence.new(val[0])}
         | reg_seq_ex reg_rep_ex
           {val[0].add(val[1])}
           
  # repeatable elements
  reg_rep_ex: reg_elm_ex
           {Repeatable.new(val[0])}
         | reg_rep_ex LEX_QUANTIFIER
           {val[0].set_quant(val[1])}

  # element (a letter or selectable element in parentheses)
  reg_elm_ex: reg_let_ex
           {val[0]}
         | LEX_PAREN_START reg_sel_ex LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}
         | LEX_PAREN_START_EX1 reg_sel_ex LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}
         | LEX_PAREN_START_EX2 reg_sel LEX_PAREN_END
           {@options[:parens].add(Paren.new(val[0], val[1], val[2]))}

  # letter
  reg_let_ex: LEX_CHAR            {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_BACK_REFER         {BackRefer.new(:LEX_BACK_REFER,   val[0])}
         | LEX_CODE_LITERAL       {TLetter.new(:LEX_CODE_LITERAL,   val[0])}
         | LEX_NAMED_REFER        {BackRefer.new(:LEX_NAMED_REFER,  val[0])}
         | LEX_NAMED_GENERATE     {BackRefer.new(:LEX_NAMED_GENERATE, val[0])}
         | LEX_CONTROL_LETTER     {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_META_LETTER        {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_ESCAPED_LETTER     {TLetter.new(:LEX_ESCAPED_LETTER, val[0])}
         | LEX_UNICODE            {TLetter.new(:LEX_UNICODE,        val[0])}
         | LEX_SIMPLIFIED_CLASS   {TLetter.new(:LEX_SIMPLIFIED_CLASS, val[0])}
         | LEX_UNICODE_CLASS      {TLetter.new(:LEX_UNICODE_CLASS,  val[0])}
         | LEX_BRACKET            {@bracket_parser.parse(val[0], @options)}   # using another parser
         | LEX_ANC_LINE_BEGIN     {Anchor.new(:LEX_ANC_LINE_BEGIN,  val[0])}
         | LEX_ANC_LINE_END       {Anchor.new(:LEX_ANC_LINE_END,    val[0])}
         | LEX_ANC_WORD_BOUND     {Anchor.new(:LEX_ANC_WORD_BOUND,  val[0])}
         | LEX_ANC_WORD_UNBOUND   {Anchor.new(:LEX_ANC_WORD_UNBOUND, val[0])}
         | LEX_ANC_STRING_BEGIN   {Anchor.new(:LEX_ANC_STRING_BEGIN, val[0])}
         | LEX_ANC_STRING_END     {Anchor.new(:LEX_ANC_STRING_END,  val[0])}
         | LEX_ANC_STRING_END2    {Anchor.new(:LEX_ANC_STRING_END2, val[0])}
         | LEX_ANC_LOOK_BEHIND2   {Anchor.new(:LEX_ANC_LOOK_BEHIND2, val[0])}
         | LEX_ANC_MATCH_START    {Anchor.new(:LEX_ANC_MATCH_START, val[0])}
         | LEX_SPECIAL_LETTER     {TLetter.new(:LEX_SPECIAL_LETTER, val[0])}
         | LEX_MINUS              {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_AND_AND            {TLetter.new(:LEX_AND_AND,        val[0])}
         | LEX_NEW_LINE           {TEmpty.new}                                # ignore new line at extended mode
         | LEX_SPACE              {TEmpty.new}                                # ignore spaces at extended mode
         | LEX_SIMPLE_ESCAPE      {TLetter.new(:LEX_SIMPLE_ESCAPE,  val[0])}
         | LEX_ANY_LETTER         {TLetter.new(:LEX_ANY_LETTER,     val[0])}
         | LEX_SHARP reg_comment_ex  {TEmpty.new}
  
  # comment of extended mode
  reg_comment_ex: LEX_NEW_LINE    # end of the comment
         | LEX_CHAR               reg_comment_ex
         | LEX_BACK_REFER         reg_comment_ex
         | LEX_CODE_LITERAL       reg_comment_ex
         | LEX_NAMED_REFER        reg_comment_ex
         | LEX_NAMED_GENERATE     reg_comment_ex
         | LEX_CONTROL_LETTER     reg_comment_ex
         | LEX_META_LETTER        reg_comment_ex
         | LEX_ESCAPED_LETTER     reg_comment_ex
         | LEX_UNICODE            reg_comment_ex
         | LEX_SIMPLIFIED_CLASS   reg_comment_ex
         | LEX_UNICODE_CLASS      reg_comment_ex
         | LEX_BRACKET            reg_comment_ex
         | LEX_ANC_LINE_BEGIN     reg_comment_ex
         | LEX_ANC_LINE_END       reg_comment_ex
         | LEX_ANC_WORD_BOUND     reg_comment_ex
         | LEX_ANC_WORD_UNBOUND   reg_comment_ex
         | LEX_ANC_STRING_BEGIN   reg_comment_ex
         | LEX_ANC_STRING_END     reg_comment_ex
         | LEX_ANC_STRING_END2    reg_comment_ex
         | LEX_ANC_LOOK_BEHIND2   reg_comment_ex
         | LEX_ANC_MATCH_START    reg_comment_ex
         | LEX_SPECIAL_LETTER     reg_comment_ex
         | LEX_MINUS              reg_comment_ex
         | LEX_AND_AND            reg_comment_ex
         | LEX_SPACE              reg_comment_ex
         | LEX_SIMPLE_ESCAPE      reg_comment_ex
         | LEX_ANY_LETTER         reg_comment_ex
         | LEX_SHARP              reg_comment_ex
         | LEX_PAREN_START        reg_comment_ex
         | LEX_PAREN_START_EX1    reg_comment_ex
         | LEX_PAREN_START_EX2    reg_comment_ex
         | LEX_PAREN_END          reg_comment_ex
         | LEX_QUANTIFIER         reg_comment_ex
         | LEX_OR                 reg_comment_ex
  
end
 
---- header
# parser classes
require 'regtest/front/empty'          # parser class for empty part ("", (|) etc.)
require 'regtest/front/letter'         # parser class for a letter
require 'regtest/front/range'          # parser class for a range of letters
require 'regtest/front/selectable'     # parser class for a selectable element
require 'regtest/front/parenthesis'    # parser class for a parenthesis
require 'regtest/front/repeatable'     # parser class for a repeatable elements
require 'regtest/front/sequence'       # parser class for a sequence of elements
require 'regtest/front/bracket'        # parser class for a character class (bracket)
require 'regtest/front/anchor'         # parser class for a anchor
require 'regtest/front/back-refer'     # parser class for a back reference
require 'regtest/front/bracket-parser' # bracket parser

---- inner
# modules for sharing procedures with bracket parser
include Regtest::Front::Empty
include Regtest::Front::Letter
include Regtest::Front::Range
include Regtest::Front::Selectable
include Regtest::Front::Parenthesis
include Regtest::Front::Repeatable
include Regtest::Front::Sequence
include Regtest::Front::Bracket
include Regtest::Front::Anchor
include Regtest::Front::BackRefer

# execute to parse
def parse(lex_words, options)
  @options = options
  
  # scanned lexical words
  @q = lex_words
  
  # bracket parser (class name is strange because of racc's restriction)
  @bracket_parser = RegtestFrontBracketParser.new
  
  # delete comments (since it is complecated to handle comments)
  @q = @q.delete_if{|token| token[0] == :LEX_COMMENT}
  
  # execute to parse
  begin
    parse_result = do_parse
  rescue Racc::ParseError => ex
    raise ex.message
  end
  
  parse_result
end

# parse next token
def next_token
  @q.shift
end

# error handling routine. commented out because of readibility problem
#def on_error(t, val, vstack)
#  if val
#    raise "Parse error. offset=#{val[1]}, letter=#{val[0]}, stack=#{vstack}"
#  else
#    raise "Parse error. t=#{t}, val=#{val}, vstack=#{vstack}"
#  end
#end

