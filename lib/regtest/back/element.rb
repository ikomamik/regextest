# encoding: utf-8
require "pp"

class Regtest::Back::Element
  def initialize(param)
    @command = param[:cmd]
    @param = param
    @nominates = param[:data] if @command == :CMD_SELECT
  end
  
  attr_reader :param, :command, :nominates
  
  # random fix
  def random_fix
    if @command == :CMD_SELECT
      result = @nominates[rand(@nominates.size)]
      @nominates = [result]   # fixed!
    else
      raise "invalid command at random_fix: #{@command}"
    end
    result
  end
  
  # size of nominates
  def size
    if(@nominates)
      @nominates.size
    else
      raise "internal error"
    end
  end
  
  # [] of nominates
  def [](num)
    if(@nominates)
      @nominates[num]
    else
      raise "internal error"
    end
  end
  
  # narrow down nominates
  def intersect(other_obj)
    raise "invalid command at intersect" if(other_obj.command != :CMD_SELECT)
    work = @nominates & other_obj.nominates
    if work.size > 0
      @nominates = work
    else
      nil
    end
  end
  
  # exclude
  def exclude(other_obj)
    raise "invalid command at exclude" if(other_obj.command != :CMD_SELECT)
    work = @nominates - other_obj.nominates
    if work.size > 0
      @nominates = work
    else
      nil
    end
  end
  
  # join nominates
  def union(other_obj)
    raise "invalid command at union" if(other_obj.command != :CMD_SELECT)
    #@nominates |= other_obj.nominates
    @nominates += other_obj.nominates # to be faster
  end
  
  # for simple pretty print
  def inspect
    case @command
    when :CMD_SELECT
      if(@nominates)
        @nominates.inspect
      else
        @param[:data].inspect
      end
    when :CMD_LOOK_BEHIND, :CMD_LOOK_AHEAD
      @param.inspect
    when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
         :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END, :CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START
      @param.inspect
    else
      raise "inner error, invalid command #{@command}"
    end
  end
  
  # Includes new line or not
  def new_line?
    @nominates.index("\n")
  end
  
  # Sets new line
  def set_new_line
    @nominates = ["\n"]
  end
  
  # Is word-elements only?
  def word_elements?
    @nominates.join("").match(/^\p{Word}+$/)
  end
  
  # is non-word-elements only?
  def non_word_elements?
    @nominates.join("").match(/^\p{^Word}+$/)
  end

  # set word-elements
  def set_word_elements
    @nominates.select!{|elem| elem.match(/^\w$/)}
  end
  
  # set non_word-elements
  def set_non_word_elements
    @nominates.select!{|elem| elem.match(/^\W$/)}
  end
  
  # checks empty
  def empty?
    @nominates.size == 0
  end
  
  # factory method to generate any char element
  def self.any_char
    # BUG: must consider other character set!
    Regtest::Back::Element.new({cmd: :CMD_SELECT, data:  (" ".."\x7e").to_a})
  end
  
  # factory method to generate any char element
  def reverse
    @nominates = ((" ".."\x7e").to_a) - @nominates
    self
  end
  

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
end


