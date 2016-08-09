# encoding: utf-8
require "pp"

class Regtest::Back::Element
  def initialize(param)
    @command = param[:cmd]
    @param = param
    @candidates = param[:data] if @command == :CMD_SELECT
  end
  
  attr_reader :param, :command, :candidates
  
  # random fix
  def random_fix
    if @command == :CMD_SELECT
      result = @candidates[rand(@candidates.size)]
      @candidates = [result]   # fixed!
    else
      raise "invalid command at random_fix: #{@command}"
    end
    result
  end
  
  # size of candidates
  def size
    if(@candidates)
      @candidates.size
    else
      raise "internal error"
    end
  end
  
  # [] of candidates
  def [](num)
    if(@candidates)
      @candidates[num]
    else
      raise "internal error"
    end
  end
  
  # narrow down candidates
  def intersect(other_obj)
    raise "invalid command at intersect" if(other_obj.command != :CMD_SELECT)
    work = @candidates & other_obj.candidates
    if work.size > 0
      @candidates = work
    else
      nil
    end
  end
  
  # exclude
  def exclude(other_obj)
    raise "invalid command at exclude" if(other_obj.command != :CMD_SELECT)
    work = @candidates - other_obj.candidates
    if work.size > 0
      @candidates = work
    else
      nil
    end
  end
  
  # join candidates
  def union(other_obj)
    raise "invalid command at union" if(other_obj.command != :CMD_SELECT)
    #@candidates |= other_obj.candidates
    @candidates += other_obj.candidates # to be faster
  end
  
  # for simple pretty print
  def inspect
    case @command
    when :CMD_SELECT
      if(@candidates)
        @candidates.inspect
      else
        @param[:data].inspect
      end
    when :CMD_LOOK_BEHIND, :CMD_LOOK_AHEAD
      @param.inspect
    when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
         :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END, :CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START,
         :CMD_ANC_LOOK_BEHIND2
      @param.inspect
    else
      raise "inner error, invalid command #{@command}"
    end
  end
  
  # Includes new line or not
  def new_line?
    @candidates.index("\n")
  end
  
  # Sets new line
  def set_new_line
    @candidates = ["\n"]
  end
  
  # Is word-elements only?
  def word_elements?
    @candidates.join("").match(/^\p{Word}+$/)
  end
  
  # is non-word-elements only?
  def non_word_elements?
    @candidates.join("").match(/^\p{^Word}+$/)
  end

  # set word-elements
  def set_word_elements
    @candidates.select!{|elem| elem.match(/^\w$/)}
  end
  
  # set non_word-elements
  def set_non_word_elements
    @candidates.select!{|elem| elem.match(/^\W$/)}
  end
  
  # checks empty
  def empty?
    @candidates.size == 0
  end
  
  # factory method to generate any char element
  def self.any_char
    # BUG: must consider other character set!
    Regtest::Back::Element.new({cmd: :CMD_SELECT, data:  (" ".."\x7e").to_a})
  end
  
  # factory method to generate any char element
  def reverse
    @candidates = ((" ".."\x7e").to_a) - @candidates
    self
  end
  

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
end


