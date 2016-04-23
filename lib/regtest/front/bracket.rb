# encoding: utf-8
require 'regtest/front/repeat'

# 文字単位の選択（ブラケット）
module Regtest::Front::Bracket
  class Bracket
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(value, elem)
      @value = value[0]
      @offset = value[1]
      @length = value[2]
      if(@value.match(/^\[\^/))
        @type = false
      else
        @type = true
      end
      @element = elem
      TstLog("Bracket: value: #{value}, type: #{@type}, elem: #{elem}")
      
      # "[^"の場合は、反転させる
      if(!@type)
        @element.reverse
      end
    end
    
    attr_reader :offset, :length
    
    # 文字列の生成
    def generate
      @element.generate(@type)
    end
    
    # 文字の列挙
    def enumerate
      @element.enumerate
    end
    
    # 結果のリセット
    def reset
      @element.reset
    end
    
    # JSONへの変換
    def json
      @@id += 1
      "{" +
        "\"type\": \"LEX_BRACKET\",  " +
        "\"id\": \"b#{@@id}\", " +
        "\"value\": #{@element.json}, " +
        "\"offset\": #{@offset}, " +
        "\"length\": #{@length} " +
      "}"
    end
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end
