# encoding: utf-8

require "pp"

# Unicodeの文字クラスの一覧を生成するスクリプト
# Unicode.orgのテーブルは使わず、Rubyの正規表現の結果を元に
# 生成するアルゴリズム

class RegtestPreUnicode
  def self.generate
    # Rubyで有効なプロパティを
    onig_properties = read_onig_properties("./contrib/Onigmo/UnicodeProps.txt")
    ranges = get_ranges_of_properties(onig_properties)
    puts_unicode_ranges('lib/regtest/front/unicode.rb', ranges)
  end

  # 鬼雲のマニュアルからUnicode文字クラスの一覧を得る
  def self.read_onig_properties(file)
    content = IO.read(file)
    class_name = nil
    properties = {}
    content.split(/\r?\n/).each_with_index do | line, i |
      # プロパティの種別
      if(line[0..0] == "*")
        class_name = line[2..-1].gsub(/\W+/, "_")
        class_name.chop! if(class_name[-1..-1] == "_")
        next
      end
      next if(!class_name || line.length == 0)
      prop_name = line.gsub(/^\s+/, "").downcase
      raise "Duplicated symbol #{prop_name}" if properties[prop_name]
      begin
        properties[prop_name] = { class: class_name, reg: /\p{#{prop_name}}+/ , ranges: []}
      rescue RegexpError
        # バージョン差異等により失敗する場合がある。現状、無視。
        warn "Regexp error at /\\p{#{prop_name}}/"
      end
      
      # デバッグ用
      # break if(i > 10)
    end
    properties
  end

  # Unicodeのスクリプト、ブロックに対応したTRangeのRubyソースの出力
  def self.get_ranges_of_properties(properties)
    puts "\nGenerating Unicode table. It takes 1-2 minutes."
    ranges = {}
    
    # 全ての文字を行列にしてからjoinで文字列に変換
    # (文字列の連結にすると性能が出ないので)
    whole_letters_array = []
    0.step(0x10ffff).each do | codepoint |
      # サロゲートの部分はスキップ
      next if (codepoint >= 0xd800 && codepoint <= 0xdfff)
      whole_letters_array.push  [codepoint].pack("U*")
    end
    whole_letters = whole_letters_array.join("")

    # 各クラスごとに作成した文字列をスキャン
    properties.each do | prop_name, value |
      whole_letters.scan(value[:reg]) do | matched |
        
        value[:ranges].push (matched[0].unpack("U*")[0]..matched[-1].unpack("U*")[0])
      end
      # puts "#{prop_name}: #{value}"
      ranges[prop_name] = value[:ranges]
    end
    ranges
  end

  # Unicodeのスクリプト、ブロックに対応したTRangeのRubyソースの出力
  def self.puts_unicode_ranges(unicode_file, ranges)
    ranges_source = ranges.keys.map { |prop_name|
      (" "*14) + "when \"#{prop_name}\"\n" +
      (" "*16) + "CharClass.new([" +
      ( ranges[prop_name].map{|range| "TRange.new(#{range.begin}, #{range.end})"}.join(", ") ) +
      "])"
    }.join("\n")
    
    template =<<"    END_OF_TEMPLATE"
      # encoding: utf-8
      # DO NOT Modify This File Since Automatically Generated

      # Unicodeのレンジ
      module Regtest::Front::Unicode
        class Unicode
          include Regtest::Front::CharClass
          include Regtest::Front::Range
          
          # ハッシュの生成
          def self.property(class_name)
            case class_name
#{ranges_source}
            else
              raise "Internal error. Class name (#\{class_name\}) not found"
            end
          end
        end
      end

      # Test suite (execute when this file is specified in command line)
      if __FILE__ == $0 
      end
    END_OF_TEMPLATE
    template.gsub!(/^      /, "")
    File.open(unicode_file, "w") do |fp|
      fp.puts template
    end
    
  end
end

RegtestPreUnicode.generate

# pp ranges
