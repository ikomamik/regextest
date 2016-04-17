# encoding: utf-8
require 'regtest/front/repeat'

# 繰り返し数付きの要素(文字やカッコ）
module Regtest::Front::Repeatable
  class Repeatable
    include Regtest::Front::Repeat
    @@id = 0   # 一意の名称を生成するための番号

    # コンストラクタ
    def initialize(value)
      TstLog("Repeatable: #{value}")
      @value = value
      @offset = value.offset
      @length = value.length
      @quant = nil
    end
    
    attr_reader :offset, :length
    
    # 繰り返し指定の追加
    def set_quant(quant_value)
      quant = quant_value[0]
      @length += quant_value[2]
      TstLog("Repeatable quant: #{quant_value}")
      if !@quant
        @quant = Repeat.new(quant)
      else
        raise "Error: syntax error, duplicate quantifier #{quant}"
      end
      self
    end
    
    # JSONへの変換
    def json
      if(@quant)
        @@id += 1
        "{\"type\": \"LEX_REPEAT\", " +
        " \"id\": \"m#{@@id}\", " +
        " \"value\": #{@value.json}, " +
        " \"offset\": #{@offset}, " +
        " \"length\": #{@length}, " +
        " \"min_repeat\": #{@quant.min_value}, " +
        " \"max_repeat\": #{@quant.max_value}}"
      else
        @value.json
      end
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end
