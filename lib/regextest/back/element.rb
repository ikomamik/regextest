# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require "pp"
require 'regextest/common'

class Regextest::Back::Element
  include Regextest::Common
  def initialize(param)
    # puts "Element param:#{param[:cmd]} data:#{param[:ranges].size}"
    @command = param[:cmd]
    @param = param
    if @command == :CMD_SELECT
      @candidates = param[:ranges].inject([]){|result, range| result += range.to_a}
    end
    # @candidates = param[:data] if @command == :CMD_SELECT
  end
  
  attr_reader :param, :command, :candidates
  
  # random fix
  def random_fix
    if @command == :CMD_SELECT
      offset = (@candidates.size > 1)?TstRand(@candidates.size):0
      result = @candidates[offset]
      @candidates = [result]   # fixed!
    else
      raise "invalid command at random_fix: #{@command}"
    end
    [result].pack("U*")   # tranforms from code point to a letter
  end
  
  # size of candidates
  def size
    if(@candidates)
      @candidates.size
    else
      raise "internal error: candidates not found at size-method"
    end
  end
  
  # [] of candidates
  def [](num)
    if(@candidates)
      @candidates[num]
    else
      raise "internal error: candidates not found at at-method"
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
        @param[:ranges].inspect
      end
    when :CMD_LOOK_BEHIND, :CMD_LOOK_AHEAD, :CMD_NOT_LOOK_BEHIND, :CMD_NOT_LOOK_AHEAD
      @param.inspect
    when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
         :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END, :CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START,
         :CMD_ANC_LOOK_BEHIND2, :CMD_ANC_RELUCTANT_BEGIN, :CMD_ANC_RELUCTANT_END
      @param.inspect
    else
      raise "inner error, invalid command #{@command}"
    end
  end
  
  # Includes new line or not
  def new_line?
    @candidates.index(0xa)
  end
  
  # Sets new line
  def set_new_line
    @candidates = [0xa]
  end
  
  # Is word-elements only?
  def word_elements?
    letters = @candidates.map{|elem| [elem].pack("U*")}
    letters.join("").match(/^\p{Word}+$/)
  end
  
  # is non-word-elements only?
  def non_word_elements?
    letters = @candidates.map{|elem| [elem].pack("U*")}
    letters.join("").match(/^\p{^Word}+$/)
  end

  # set word-elements
  def set_word_elements
    @candidates.select!{|elem| [elem].pack("U*").match(/^\w$/)}
  end
  
  # set non_word-elements
  def set_non_word_elements
    @candidates.select!{|elem| [elem].pack("U*").match(/^\W$/)}
  end
  
  # checks empty
  def empty?
    @candidates.size == 0
  end
  
  # factory method to generate any char element
  def self.any_char
    # BUG: must consider other character set!
    Regextest::Back::Element.new({cmd: :CMD_SELECT, ranges:  [0x20..0x7e]})
  end
  
  # factory method to generate any char element
  def reverse
    @candidates = ((0x20..0x7e).to_a) - @candidates
    self
  end
  

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
end


