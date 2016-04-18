# encoding: utf-8

require 'regtest/regex-option'         # Options of regex

# selectable elements
module Regtest::Front::Selectable
  class Selectable
    include Regtest::Common
    @@id = 0   # a class variable for generating unique name of element
    
    attr_reader :offset, :length

    # コンストラクタ
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @nominates = value
        @offset = value[0].offset
        @length = value[-1].offset + value[-1].length - value[0].offset
      else
        @nominates = [value]
        @offset = value.offset
        @length = value.length
      end
    end
    
    # 選択肢の追加
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @nominates.push value
      @length = value.offset - @offset + value.length
      self
    end
    
    # JSONへの変換
    def json
      @@id += 1
      "{" +
        "\"type\": \"LEX_SELECT\", \"id\": \"S#{@@id}\", " +
        "\"offset\": #{@offset}, \"length\": #{@length}, " +
        "\"value\": [" + @nominates.map{|elem| elem.json}.join(",") +
      "]}"
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

