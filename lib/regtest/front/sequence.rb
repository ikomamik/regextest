# encoding: utf-8
require 'regtest/front/repeat'

# Sequence of elements (letter or parenthesis)
module Regtest::Front::Sequence
  class Sequence
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(elem)
      TstLog("Sequence: #{elem}")
      @offset = elem.offset
      @length = elem.length
      @elements = [elem]
    end
    
    attr_reader :offset, :length
    
    # add an element (a letter or a parenthesis) to sequence
    def add(elem)
      TstLog("Sequence add: #{elem}")
      @elements.push elem
      @length += elem.length
      self
    end
    
    # 文字列の生成
    def generate
      results = @elements.map{|elem| elem.generate}
      if(results.index(nil))
        puts "seq nil"
        nil
      else
        results.join("")
      end
    end
    
    # 結果のリセット
    def reset
      @elements.each do | element |
        element.reset
      end
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
