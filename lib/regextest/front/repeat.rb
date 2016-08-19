# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

# Quantifier class
module Regextest::Front::Repeat
  class Repeat
    include Regextest::Common
  
    # Constants for the class
    TstOptGreedy      =  1
    TstOptReluctant   =  2
    TstOptPossessive  =  4
    
    # Constructor
    def initialize(param)
      @min_value = 1
      @max_value = 1
      @option = 0
      set_values(param) if(param)
    end
    attr_reader :max_value, :min_value, :option
    
    # get minimum, maximum, and option
    def set_values(param)
      case param
      when '?', '??', '?+'
        @min_value = 0
        @max_value = 1
        @option |= TstOptGreedy     if(param.size == 1)
        @option |= TstOptReluctant  if(param == "??")
        @option |= TstOptPossessive if(param[-1] == "+")
      when '*', '*?', '*+'
        @min_value = 0
        @max_value = TstConstRepeatMax
        @option |= TstOptGreedy     if(param.size == 1)
        @option |= TstOptReluctant  if(param[-1] == "?")
        @option |= TstOptPossessive if(param[-1] == "+")
      when '+', '+?', '++'
        @min_value = 1
        @max_value = TstConstRepeatMax
        @option |= TstOptGreedy     if(param.size == 1)
        @option |= TstOptReluctant  if(param[-1] == "?")
        @option |= TstOptPossessive if(param == "++")
      when /^\{(\d+)\}([\?\+]?)$/         # {3}, etc.
        @min_value = $1.to_i
        @max_value = $1.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{(\d+),(\d+)\}([\?\+]?)$/   # {2,3}, etc.
        @min_value = $1.to_i
        @max_value = $2.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{,(\d+)\}([\?\+]?)$/        # {,3}, etc.
        @min_value = 0
        @max_value = $1.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{(\d+),\}([\?\+]?)$/        # {3,}, etc.
        @min_value = $1.to_i
        @max_value = TstConstRepeatMax
        @max_value = @min_value + TstConstRepeatMax if(@max_value < @min_value)
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      else
        raise "Error: repeat notation #{param} invalid"
      end
    end
    
    # a+?, etc.
    def is_reluctant?
      ((@option & TstOptReluctant) != 0)
    end
    
    # a++. etc.
    def is_possessive?
      ((@option & TstOptPossessive) != 0)
    end
    
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
