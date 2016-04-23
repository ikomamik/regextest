# encoding: utf-8

# ブラケットの中のレンジ
module Regtest::Front::Range
  class TRange
    @@id = 0   # a class variable for generating unique name of element

    # Constructor
    def initialize(letter_begin, letter_end = nil)
      @begin = parse_letter(letter_begin)
      if(letter_end)
        @end = parse_letter(letter_end)
      else
        @end = @begin
      end
      TstLog("TRange: #{@begin}-#{@end}")
      @range = generate_range(@begin, @end)
      @offset = -1  # not used in this class
      @length = -1  # not used in this class
    end
    
    attr_reader :offset, :length
    
    # 文字列の生成
    def parse_letter(letter)
      case letter
      when String
        letter
      when Integer
        [letter].pack("U*")
      else
        letter.generate
      end
    end
    
    # 文字列の生成
    def generate
      offset = rand(@range.size)
      [@range[offset]].pack("U*")
    end
    
    # レンジの生成(ユニコードのコードポイントの配列を生成）
    def generate_range(letter_begin, letter_end)
      char_ords = []
      (letter_begin.unpack("U*")[0]..letter_end.unpack("U*")[0]).to_a.each do |codepoint|
        char_ords.push codepoint
      end
      char_ords
    end
    
    # 文字の列挙
    def enumerate
      @range.map{|codepoint| [codepoint].pack("U*")}
    end
    
    # リセット
    def reset
      # 何もしない
    end
    
    # JSONへの変換(Unicodeのコードポイントにする）
    def json
      @@id += 1
      work_begin = @begin.unpack("U*")[0]
      work_end   = @end.unpack("U*")[0]

      "{\"type\": \"LEX_RANGE\", \"id\": \"G#{@@id}\", \"begin\": #{work_begin}, \"end\": #{work_end}}"
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

