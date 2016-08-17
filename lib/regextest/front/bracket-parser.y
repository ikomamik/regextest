# encoding: utf-8

# This class name will be modified by Rake process
class RegextestFrontBracketParser
options no_result_var
rule
  # a set of sequences in a bracket (regarding && operator)
  brc_sq1: brc_sq2
           {val[0]}
         | brc_sq1 LEX_AND_AND brc_sq2
           {val[0].and(val[2])}
           
  # a first char of elements
  brc_sq2: LEX_BRACKET_END brc_sq3   # ']' as a first entry is valid
           {val[1].add(TLetter.new(:LEX_CHAR,val[0]))}
         | LEX_BRACKET_END           # '[]]' or '[^]]' pattern 
           {CharClass.new(TLetter.new(:LEX_CHAR,val[0]))}
         | brc_sq3
  
  # a sequence of elements
  brc_sq3: brc_elm
           {CharClass.new(val[0])}
         | brc_sq3 brc_elm
           {val[0].add(val[1])}
           
  # a element (a letter, a character class, a range or another bracket)
  brc_elm: brc_lt1 LEX_MINUS brc_lt1
           {TRange.new(val[0], val[2])}
         | brc_lt1
           {val[0]}
         | brc_lt2
           {val[0]}
         | reg_bracket
           {val[0]}  # note!

  # bracket in a bracket
  reg_bracket: LEX_BRACKET_START  brc_sq1 LEX_BRACKET_END
               {Bracket.new(val[0], val[1])}
             | LEX_BRACKET_START2 brc_sq1 LEX_BRACKET_END
               {Bracket.new(val[0], val[1])}

  # a letter (can be expressed as x-y)
  brc_lt1: LEX_CHAR               {TLetter.new(:LEX_CHAR,           val[0])}
         | LEX_OCTET              {TLetter.new(:LEX_OCTET,          val[0])}
         | LEX_SIMPLE_ESCAPE      {TLetter.new(:LEX_SIMPLE_ESCAPE,  val[0])}
         | LEX_MINUS              {TLetter.new(:LEX_CHAR,           val[0])}   # minus as a first letter
         | LEX_CODE_LITERAL       {TLetter.new(:LEX_CODE_LITERAL,   val[0])}
         | LEX_CONTROL_LETTER     {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_META_LETTER        {TLetter.new(:LEX_CONTROL_LETTER, val[0])}
         | LEX_ESCAPED_LETTER     {TLetter.new(:LEX_ESCAPED_LETTER, val[0])}
         | LEX_UNICODE            {TLetter.new(:LEX_UNICODE,        val[0])}

  # a character class
  brc_lt2: LEX_POSIX_CHAR_CLASS   {TLetter.new(:LEX_POSIX_CHAR_CLASS, val[0])}
         | LEX_SIMPLIFIED_CLASS   {TLetter.new(:LEX_SIMPLIFIED_CLASS, val[0])}
         | LEX_UNICODE_CLASS      {TLetter.new(:LEX_UNICODE_CLASS,  val[0])}
         | LEX_SPECIAL_LETTER     {TLetter.new(:LEX_SPECIAL_LETTER, val[0])}
         | LEX_SPACE              {TLetter.new(:LEX_SPACE,          val[0])}
         
end

---- header
# parser classes
require 'regextest/front/bracket-scanner'  # scanner class (for splitting the string)
require 'regextest/front/letter'           # parser class for a letter
require 'regextest/front/range'            # parser class for a range of letters
require 'regextest/front/char-class'       # parser class for a char-class element
require 'regextest/front/bracket'          # parser class for a bracket

---- inner
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

