# encoding: utf-8

require 'regtest/front/range'          # 文字要素のレンジ
require 'regtest/regex-option'         # 正規表現のオプション

# 選択肢を許す要素
module Regtest::Front::Selectable
  class Selectable
    include Regtest::Common
    include Regtest::Front::Range
    @@id = 0   # 一意の名称を生成するための番号
    
    attr_reader :nominates, :offset, :length

    # コンストラクタ
    def initialize(value)
      TstLog("Selectlable: #{value}")
      @reg_options = @@parse_options[:reg_options]
      case value
      when Array
        @nominates = value
        @offset = -1 # value[0].offset
        @length = -1 # value[-1].offset + value[-1].length - value[0].offset
      when TRange
        @nominates = [value]
        @offset = -1
        @length = -1
      else
        @nominates = [value]
        @offset = value.offset
        @length = value.length
      end
      
      # 全ての文字集合を求める
      @whole_set = get_whole_set
    end
    
    # 選択肢の追加
    def add(value)
      TstLog("Selectlable add: #{value}"); 
      @nominates.push value
      @length = value.offset - @offset + value.length
      self
    end
    
    # 選択肢の反転(ブラケットの時のみ有効)
    def reverse
      TstLog("Selectlable reverse"); 

      # 全ての集合から文字を削除
      whole = @whole_set.dup
      @nominates.each do | nominate |
        whole -= nominate.enumerate
      end
      
      # 隣り合ったコードポイントの文字はTRangeとして再構成する
      @nominates = reconstruct_nominates(whole)
    end

    # 選択肢の再構成
    def reconstruct_nominates(char_set)
      # 各文字をコードポイントに変換
      code_points = char_set.map{|letter| letter.unpack("U*")[0]}
      
      # 隣り合ったコードポイントの文字はTRangeとして再構成する
      new_nominates = []
      range_start = range_end = code_points.shift
      while(codepoint = code_points.shift)
        if(codepoint == range_end + 1)
          range_end = codepoint
        else
          new_nominates.push TRange.new([range_start].pack("U*"), [range_end].pack("U*"))
          range_start = range_end = codepoint
        end
      end
      new_nominates.push TRange.new([range_start].pack("U*"), [range_end].pack("U*"))
      @nominates = new_nominates
    end
    
    # 選択肢のAND
    def and(other_selectable)
      TstLog("Selectlable and: #{other_selectable}");

      # 文字レベルで共通のものを求める
      char_set = enumerate & other_selectable.enumerate
      
      # 隣り合ったコードポイントの文字はTRangeとして再構成する
      @nominates = reconstruct_nominates(char_set)

      pp @nominates
      self
    end
    
    # 全ての文字集合
    def get_whole_set
      if( @reg_options.is_multiline? )
        work = [ TRange.new("\x20", "\x7e"),  TRange.new("\n")]
      else
        work = [ TRange.new("\x20", "\x7e") ]
      end
      work.inject([]){|result,elem| result |= elem.enumerate}
    end
    
    # 文字列の生成
    def generate
      offsets = (0 ... @nominates.size).to_a.shuffle
      result = nil
      offsets.each do | offset |
        result = @nominates[offset].generate
        break if(result)
      end
      result
    end
    
    # 文字の列挙
    def enumerate
      @nominates.inject([]){|result, nominate| result += nominate.enumerate}
    end
    
    # 結果のリセット
    def reset
      @nominates.each do | nominate |
        nominate.reset
      end
    end
    
    # JSONへの変換
    def json
      #if @nominates.size > 1
        @@id += 1
        "{" +
          "\"type\": \"LEX_SELECT\", \"id\": \"S#{@@id}\", " +
          "\"offset\": #{@offset}, \"length\": #{@length}, " +
          "\"value\": [" + @nominates.map{|elem| elem.json}.join(",") +
        "]}"
      #else
      #  @nominates[0].json
      #end
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

