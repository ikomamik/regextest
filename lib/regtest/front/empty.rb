# encoding: utf-8

# Empty part
module Regtest::Front::Empty
  class TEmpty
    @@id = 0   # 一意の名称を生成するための番号

    # コンストラクタ
    def initialize
      @offset = -1
      @length = 0
    end
    
    attr_reader :offset, :length
    
    # JSONへの変換(Unicodeのコードポイントにする）
    def json
      @@id += 1
        "{" +
           "\"type\": \"LEX_EMPTY\", \"id\": \"E#{@@id}\", \"value\": \"\", " +
           "\"offset\": #{@offset}, \"length\": #{@length}" +
        "}"
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

