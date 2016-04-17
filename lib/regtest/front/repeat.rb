# encoding: utf-8

# 繰り返し数を解析するクラス
module Regtest::Front::Repeat
  class Repeat
    # 定数
    TstConstRepeatMax =  (ENV['TST_MAX_REPEAT'])?(ENV['TST_MAX_REPEAT'].to_i):32
    
    TstOptGreedy      =  1
    TstOptReluctant   =  2
    TstOptPossessive  =  4
    
    # コンストラクタ
    def initialize(param)
      @min_value = 1
      @max_value = 1
      @option = 0
      set_values(param) if(param)
    end
    attr_reader :max_value, :min_value
    
    # 最小値、最大値、オプションを求める
    def set_values(param)
      case param
      when '?', '??', '?+'
        @min_value = 0
        @max_value = 1
        @option |= TstOptGreedy     if(param.size == 1)
        @option |= TstOptReluctant  if(param[-1] == "?")
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
        @option |= TstOptPossessive if(param[-1] == "+")
      when /^\{(\d+)\}([\?\+]?)$/         # {3} のパターン
        @min_value = $1.to_i
        @max_value = $1.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{(\d+),(\d+)\}([\?\+]?)$/   # {2,3}のパターン
        @min_value = $1.to_i
        @max_value = $2.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{,(\d+)\}([\?\+]?)$/        # {,3}のパターン
        @min_value = 0
        @max_value = $1.to_i
        @option |= TstOptGreedy     if(!$2)
        @option |= TstOptReluctant  if($2 == "?")
        @option |= TstOptPossessive if($2 == "+")
      when /^\{(\d+),\}([\?\+]?)$/        # {3,}のパターン
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
    
    # 繰り返し数を生成(現在、オプションは実装されていない）
    def generate
      @min_value + rand(1 + @max_value - @min_value)
    end

  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end
