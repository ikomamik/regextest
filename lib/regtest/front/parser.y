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

  # letter
  reg_let: LEX_CHAR               {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_BACK_REFER         {BackRefer.new(:LEX_BACK_REFER,   val[0])}
         | LEX_CODE_LITERAL       {TLetter.new(:LEX_CODE_LITERAL,   val[0])}
         | LEX_NAMED_REFER        {BackRefer.new(:LEX_NAMED_REFER,  val[0])}
         | LEX_NAMED_GENERATE     {BackRefer.new(:LEX_NAMED_GENERATE, val[0])}
         | LEX_CONTROL_LETTER     {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
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
        #| LEX_ANC_MATCH_START    {Anchor.new(:LEX_ANC_MATCH_START, val[0])}  # included in Onigmo but not in Ruby
         | LEX_SPECIAL_LETTER     {TLetter.new(:LEX_SPECIAL_LETTER, val[0])}
         | LEX_MINUS              {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_AND_AND            {TLetter.new(:LEX_AND_AND,        val[0])}
         | LEX_SPACE              {TLetter.new(:LEX_SPACE,          val[0])}
         | LEX_ANY_LETTER         {TLetter.new(:LEX_ANY_LETTER,     val[0])}

end
 
---- header
# parser classes
require 'regtest/front/scanner'        # scanner class (for splitting the string)
require 'regtest/front/empty'          # parser class for empty part ("", (|) etc.)
require 'regtest/front/letter'         # parser class for a letter
require 'regtest/front/range'          # parser class for a range of letters
require 'regtest/front/selectable'     # parser class for a selectable element
require 'regtest/front/parenthesis'    # parser class for a parenthesis
require 'regtest/front/manage-parentheses'   # management class of parentheses
require 'regtest/front/repeatable'     # parser class for a repeatable elements
require 'regtest/front/sequence'       # parser class for a sequence of elements
require 'regtest/front/bracket'        # parser class for a character class (bracket)
require 'regtest/front/anchor'         # parser class for a anchor
require 'regtest/front/back-refer'     # parser class for a back reference
require 'regtest/front/bracket-parser' # bracket parser
require 'regtest/regex-option'         # option of the regular expression

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
include Regtest::Front::ManageParentheses

# execute to parse
def parse(str, options)
  @options = options
  
  # scanning the string
  scanner = Regtest::Front::Scanner.new(options)
  @q = scanner.scan(str)
  
  # initialize management class of parentheses
  @options[:parens] = Parens.new()

  # bracket parser (class name is strange because of racc's restriction)
  @bracket_parser = RegtestFrontBracketParser.new
  
  # delete comments (since it is complecated to handle comments)
  @q = @q.delete_if{|token| token[0] == :LEX_COMMENT}
  
  # if extended option specified, delete spaces from string
  if( @options[:reg_options].is_extended? )
    @q = @q.delete_if{|token| (token[0] == :LEX_EXTENDED_COMMENT || token[0] == :LEX_SPACE)}
  end

  # execute to parse
  begin
    parse_result = do_parse
  rescue Racc::ParseError => ex
    raise ex.message
  end
  
  # sort parentheses (since number of parenthesis is offset-order other than parsing-order)
  @options[:parens].sort
  
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

