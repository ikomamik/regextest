#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.14
# from Racc grammer file "".
#

require 'racc/parser.rb'

# parser classes
require 'regextest/front/bracket-scanner'  # scanner class (for splitting the string)
require 'regextest/front/letter'           # parser class for a letter
require 'regextest/front/range'            # parser class for a range of letters
require 'regextest/front/char-class'       # parser class for a char-class element
require 'regextest/front/bracket'          # parser class for a bracket

class RegextestFrontBracketParser < Racc::Parser

module_eval(<<'...end bracket-parser.y/module_eval...', 'bracket-parser.y', 76)
# modules for sharing procedures with main (regex) parser
include Regextest::Front::Range
include Regextest::Front::Letter
include Regextest::Front::CharClass
include Regextest::Front::Bracket

# execute to parse
def parse(value, options)
  @bracket_str = value[0]
  @options = options

  # check / verify input string
  if(!md = @bracket_str.match(/^(\[\^?)(.*)\]$/))
    raise "Internal error. bracket notation error"
  end
  bracket_header = md[1]
  seq_str = md[2]
    
  # scanning for spliting into elements
  scanner = Regextest::Front::BracketScanner.new(options)
  @q = scanner.scan(seq_str)
  
  # execute to parse
  begin
    parse_result = do_parse
  rescue Racc::ParseError => ex
    raise "Bracket " + ex.message
  end
  
  
  # return an analized bracket to main routine
  Bracket.new(value, parse_result)
end

# parse next token
def next_token
  @q.shift
end

# error handling routine
#def on_error(t, val, vstack)
  ## warn "t=#{t}, val=#{val}, vstack=#{vstack}"
  #raise "Bracket Parse error. str=#{@bracket_str} offset=#{val[1]}, letter=#{val[0]}, stack=#{vstack}"
#end
...end bracket-parser.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
     3,    14,     9,    10,    11,    12,    13,    15,    16,    17,
    18,    19,    20,    21,    22,    23,    24,    25,     3,    14,
     9,    10,    11,    12,    13,    15,    16,    17,    18,    19,
    20,    21,    22,    23,    24,    25,     3,    14,     9,    10,
    11,    12,    13,    15,    16,    17,    18,    19,    20,    21,
    22,    23,    24,    25,     3,    14,     9,    10,    11,    12,
    13,    15,    16,    17,    18,    19,    20,    21,    22,    23,
    24,    25,    14,     9,    10,    11,    12,    13,    15,    16,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    14,
     9,    10,    11,    12,    13,    15,    16,    17,    18,    19,
    20,    21,    22,    23,    24,    25,    14,     9,    10,    11,
    12,    13,    15,    16,    17,    18,    19,    20,    21,    22,
    23,    24,    25,    14,    27,    36,    11,    12,    13,    15,
    16,    17,    18,    19,    20,    26,    33,    27,    27,    37,
    30 ]

racc_action_check = [
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    27,    27,
    27,    27,    27,    27,    27,    27,    27,    27,    27,    27,
    27,    27,    27,    27,    27,    27,     9,     9,     9,     9,
     9,     9,     9,     9,     9,     9,     9,     9,     9,     9,
     9,     9,     9,     9,    10,    10,    10,    10,    10,    10,
    10,    10,    10,    10,    10,    10,    10,    10,    10,    10,
    10,    10,    28,    28,    28,    28,    28,    28,    28,    28,
    28,    28,    28,    28,    28,    28,    28,    28,    28,     4,
     4,     4,     4,     4,     4,     4,     4,     4,     4,     4,
     4,     4,     4,     4,     4,     4,     3,     3,     3,     3,
     3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
     3,     3,     3,    30,    31,    31,    30,    30,    30,    30,
    30,    30,    30,    30,    30,     1,    26,     1,    32,    32,
     6 ]

racc_action_pointer = [
    -3,   135,   nil,   102,    85,   nil,   136,   nil,   nil,    33,
    51,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   136,    15,    68,   nil,
   119,   122,   136,   nil,   nil,   nil,   nil,   nil ]

racc_action_default = [
   -30,   -30,    -1,    -4,    -5,    -6,   -10,   -11,   -12,   -30,
   -30,   -15,   -16,   -17,   -18,   -19,   -20,   -21,   -22,   -23,
   -24,   -25,   -26,   -27,   -28,   -29,   -30,   -30,    -3,    -7,
    -9,   -30,   -30,    38,    -2,    -8,   -13,   -14 ]

racc_goto_table = [
    29,     1,    28,    34,    35,   nil,   nil,   nil,   nil,   nil,
    31,    32,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,    29 ]

racc_goto_check = [
     4,     1,     3,     2,     5,   nil,   nil,   nil,   nil,   nil,
     1,     1,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,     4 ]

racc_goto_pointer = [
   nil,     1,   -24,    -1,    -4,   -26,   nil,   nil ]

racc_goto_default = [
   nil,   nil,     2,     4,     5,     6,     7,     8 ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 22, :_reduce_1,
  3, 22, :_reduce_2,
  2, 23, :_reduce_3,
  1, 23, :_reduce_4,
  1, 23, :_reduce_none,
  1, 24, :_reduce_6,
  2, 24, :_reduce_7,
  3, 25, :_reduce_8,
  2, 25, :_reduce_9,
  1, 25, :_reduce_10,
  1, 25, :_reduce_11,
  1, 25, :_reduce_12,
  3, 28, :_reduce_13,
  3, 28, :_reduce_14,
  1, 26, :_reduce_15,
  1, 26, :_reduce_16,
  1, 26, :_reduce_17,
  1, 26, :_reduce_18,
  1, 26, :_reduce_19,
  1, 26, :_reduce_20,
  1, 26, :_reduce_21,
  1, 26, :_reduce_22,
  1, 26, :_reduce_23,
  1, 26, :_reduce_24,
  1, 27, :_reduce_25,
  1, 27, :_reduce_26,
  1, 27, :_reduce_27,
  1, 27, :_reduce_28,
  1, 27, :_reduce_29 ]

racc_reduce_n = 30

racc_shift_n = 38

racc_token_table = {
  false => 0,
  :error => 1,
  :LEX_AND_AND => 2,
  :LEX_BRACKET_END => 3,
  :LEX_MINUS => 4,
  :LEX_BRACKET_START => 5,
  :LEX_BRACKET_START2 => 6,
  :LEX_CHAR => 7,
  :LEX_OCTET => 8,
  :LEX_SIMPLE_ESCAPE => 9,
  :LEX_CODE_LITERAL => 10,
  :LEX_CONTROL_LETTER => 11,
  :LEX_META_CONTROL_LETTER => 12,
  :LEX_META_LETTER => 13,
  :LEX_ESCAPED_LETTER => 14,
  :LEX_UNICODE => 15,
  :LEX_POSIX_CHAR_CLASS => 16,
  :LEX_SIMPLIFIED_CLASS => 17,
  :LEX_UNICODE_CLASS => 18,
  :LEX_SPECIAL_LETTER => 19,
  :LEX_SPACE => 20 }

racc_nt_base = 21

racc_use_result_var = false

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "LEX_AND_AND",
  "LEX_BRACKET_END",
  "LEX_MINUS",
  "LEX_BRACKET_START",
  "LEX_BRACKET_START2",
  "LEX_CHAR",
  "LEX_OCTET",
  "LEX_SIMPLE_ESCAPE",
  "LEX_CODE_LITERAL",
  "LEX_CONTROL_LETTER",
  "LEX_META_CONTROL_LETTER",
  "LEX_META_LETTER",
  "LEX_ESCAPED_LETTER",
  "LEX_UNICODE",
  "LEX_POSIX_CHAR_CLASS",
  "LEX_SIMPLIFIED_CLASS",
  "LEX_UNICODE_CLASS",
  "LEX_SPECIAL_LETTER",
  "LEX_SPACE",
  "$start",
  "brc_sq1",
  "brc_sq2",
  "brc_sq3",
  "brc_elm",
  "brc_lt1",
  "brc_lt2",
  "reg_bracket" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'bracket-parser.y', 10)
  def _reduce_1(val, _values)
    val[0]
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 12)
  def _reduce_2(val, _values)
    val[0].and(val[2])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 16)
  def _reduce_3(val, _values)
    val[1].add(TLetter.new(:LEX_CHAR,val[0]))
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 18)
  def _reduce_4(val, _values)
    CharClass.new(TLetter.new(:LEX_CHAR,val[0]))
  end
.,.,

# reduce 5 omitted

module_eval(<<'.,.,', 'bracket-parser.y', 23)
  def _reduce_6(val, _values)
    CharClass.new(val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 25)
  def _reduce_7(val, _values)
    val[0].add(val[1])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 29)
  def _reduce_8(val, _values)
    TRange.new(val[0], val[2])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 31)
  def _reduce_9(val, _values)
    CharClass.new(val[0]).add(TLetter.new(:LEX_CHAR, val[1]))
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 33)
  def _reduce_10(val, _values)
    val[0]
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 35)
  def _reduce_11(val, _values)
    val[0]
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 37)
  def _reduce_12(val, _values)
    val[0]
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 41)
  def _reduce_13(val, _values)
    Bracket.new(val[0], val[1])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 43)
  def _reduce_14(val, _values)
    Bracket.new(val[0], val[1])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 46)
  def _reduce_15(val, _values)
    TLetter.new(:LEX_CHAR,           val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 47)
  def _reduce_16(val, _values)
    TLetter.new(:LEX_OCTET,          val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 48)
  def _reduce_17(val, _values)
    TLetter.new(:LEX_SIMPLE_ESCAPE,  val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 49)
  def _reduce_18(val, _values)
    TLetter.new(:LEX_CHAR,           val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 50)
  def _reduce_19(val, _values)
    TLetter.new(:LEX_CODE_LITERAL,   val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 51)
  def _reduce_20(val, _values)
    TLetter.new(:LEX_CONTROL_LETTER, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 52)
  def _reduce_21(val, _values)
    TLetter.new(:LEX_META_CONTROL_LETTER, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 53)
  def _reduce_22(val, _values)
    TLetter.new(:LEX_CONTROL_LETTER, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 54)
  def _reduce_23(val, _values)
    TLetter.new(:LEX_ESCAPED_LETTER, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 55)
  def _reduce_24(val, _values)
    TLetter.new(:LEX_UNICODE,        val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 58)
  def _reduce_25(val, _values)
    TLetter.new(:LEX_POSIX_CHAR_CLASS, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 59)
  def _reduce_26(val, _values)
    TLetter.new(:LEX_SIMPLIFIED_CLASS, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 60)
  def _reduce_27(val, _values)
    TLetter.new(:LEX_UNICODE_CLASS_BRACKET,  val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 61)
  def _reduce_28(val, _values)
    TLetter.new(:LEX_SPECIAL_LETTER, val[0])
  end
.,.,

module_eval(<<'.,.,', 'bracket-parser.y', 62)
  def _reduce_29(val, _values)
    TLetter.new(:LEX_SPACE,          val[0])
  end
.,.,

def _reduce_none(val, _values)
  val[0]
end

end   # class RegextestFrontBracketParser
