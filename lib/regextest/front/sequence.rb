# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/front/repeat'

# Sequence of elements (letter or parenthesis)
module Regextest::Front::Sequence
  class Sequence
    include Regextest::Common
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(elem)
      TstLog("Sequence: #{elem}")
      @offset = elem.offset
      @length = elem.length
      @elements = [elem]
    end
    
    attr_reader :offset, :length, :elements
    
    # add an element (a letter or a parenthesis) to sequence
    def add(elem)
      TstLog("Sequence add: #{elem}")
      @elements.push elem
      @length += elem.length
      self
    end
    
    # concatinate other sequence object to sequence
    def concatinate(other_obj)
      TstLog("Sequence concatinate: #{other_obj}")
      @elements += other_obj.elements
      @length += other_obj.length
      self
    end
    
    # set options
    def set_options(options)
      TstLog("Sequence set_options: #{options[:reg_options].inspect}")

      # dup for preventing from rewrite in the sequence
      new_options = options.dup
      new_options[:reg_options] = options[:reg_options].dup
      
      # call elements of the sequence
      @elements.each do | element |
        element.set_options(new_options)
      end
      self
    end
    
    # transform to json format
    def json
      # if @elements.size > 1
        @@id += 1
        "{\"type\": \"LEX_SEQ\", " +
        " \"id\": \"q#{@@id}\", " +
        " \"offset\": \"#{@offset}\", " +
        " \"length\": \"#{@length}\", " +
        " \"value\": [#{@elements.map{|elem| elem.json}.join(",")}]}"
      # else
      #  @elements[0].json
      #end
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
