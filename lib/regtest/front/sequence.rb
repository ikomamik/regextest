# encoding: utf-8
require 'regtest/front/repeat'

# 要素のシーケンス
module Regtest::Front::Sequence
  class Sequence
    @@id = 0   # a class variable for generating unique name of element

    # コンストラクタ
    def initialize(elem)
      TstLog("Sequence: #{elem}")
      @offset = elem.offset
      @length = elem.length
      @elements = [elem]
    end
    
    attr_reader :offset, :length
    
    # 要素の追加
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
    
    # JSONへの変換
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

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end
