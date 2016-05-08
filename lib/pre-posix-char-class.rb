# encoding: utf-8

# CURRENTLY NOT USED

require "pp"

# 鬼雲のマニュアルからPOSIX文字クラスの定義を得る
def get_onigmo_posix_char_class(file, hash)
  content = IO.read(file)
  if(!md = content.match(/\r?\n\d\.\s+Character\s+class.+?   Unicode Case:(.+?)\r?\n\r?\n\r?\n/m))
    raise "#{file} format is unmatched"
  end
  posix_def = md[1]
  posix_def.gsub!(/\r?\n+/m, "\n")
  posix_def.gsub!(/\|\r?\n/m, "|")
  posix_def.split(/\r?\n/).each do | line |
    elems = line.split(/\s+/)
    if(elems[1] && elems[1].match(/^\w+$/) && elems[2])
      raise "Duplicated symbol #{elems[1]}" if hash[elems[1]]
      hash[elems[1]] = elems[2..-1].join("")
    end
  end
end

# 鬼雲のマニュアルからUnicode文字クラスの一覧を得る
def get_onigmo_unicode_propety_class(file, hash)
  content = IO.read(file)
  class_name = nil
  content.split(/\r?\n/).each do | line |
    if(line[0..0] == "*")
      class_name = line[2..-1].gsub(/\W+/, "_")
      class_name.chop! if(class_name[-1..-1] == "_")
      next
    end
    next if(!class_name || line.length == 0)
    prop_name = line.gsub(/^\s+/, "")
    raise "Duplicated symbol #{prop_name}" if hash[prop_name]
    hash[prop_name] = class_name.to_sym
  end
end

hash = {}
get_onigmo_posix_char_class("../contrib/onigmo/RE.txt", hash)
# get_onigmo_unicode_propety_class("../contrib/onigmo/UnicodeProps.txt", hash)
pp hash
exit





# Unicode定義ファイルの共通文法の処理
def read_unicode_line(file)
  content = IO.read(file)
  content.split(/\r?\n/).each do | line |
    next if(line.length == 0 || line[0..0] == '#')
    yield(line)
  end
end

# スクリプトファイルの読み込み
def read_scripts(scripts_file, ranges)
  read_unicode_line(scripts_file) do | line |
    if(md = line.match(/^(\h{4,6})(?:\.\.(\h{4,6}))?\s+;\s+(\w+)\s+#\s+(\S+)\s+/))
      range_start = md[1].hex
      range_end   = (md[2])?(md[2].hex):(range_start)

      script1 = md[3]
      script2 = md[4]
      script2 = "LC" if(script2 == "L&")
      script3 = script2[0..0]

      #puts "range: [#{range_start}:#{range_end}]\t#{script1}\t#{script2}"
      [script1, script2, script3].each do | script |
        if(ranges[script])
          if(range_start == ranges[script][-1][1] + 1)
            ranges[script][-1][1] = range_end
          else
            ranges[script].push [range_start, range_end]
          end
        else
          ranges[script] = [[range_start, range_end]]
        end
      end
        
    else
      raise "syntax error: #{line}"
    end
  end
end

# ブロックファイルの読み込み
def read_blocks(blocks_file, ranges)
  read_unicode_line(blocks_file) do | line |
    if(md = line.match(/^(\h{4,6})\.\.(\h{4,6})\s*;\s+(.+)$/))
      range_start = md[1].hex
      range_end   = md[2].hex
      block_name = "In_" + md[3].gsub(/\W/, "_")
      if ranges[block_name]
        raise "block name #{block_name} is already used"
      else
        ranges[block_name] = [[range_start, range_end]]
      end
    end
  end
end

# Unicodeのスクリプト、ブロックに対応したTRangeのRubyソースの出力
def puts_unicode_ranges(unicode_file, ranges)
  ranges_source = ranges.keys.map { |class_name|
    (" "*12) +
    "hash[\"#{class_name}\"] = CharClass.new([" +
    ( ranges[class_name].map{|range| "TRange.new(#{range[0]}, #{range[1]})"}.join(", ") ) +
    "])"
  }.join("\n")
  
  template =<<"  END_OF_TEMPLATE"
    # encoding: utf-8
    # DO NOT Modify This File Since Automatically Generated

    # Unicodeのレンジ
    module Regtest::Front::ParseUnicode
      class Unicode
        # ハッシュの生成
        def self.ranges()
          hash = {}
#{ranges_source}
          hash
        end
      end
    end

    # Test suite (execute when this file is specified in command line)
    if __FILE__ == $0 
    end
  END_OF_TEMPLATE
  template.gsub!(/^    /, "")
  File.open(unicode_file, "w") do |fp|
    fp.puts template
  end
  
end

ranges = {}
read_scripts("./unicode/Scripts.txt", ranges)
read_blocks("./unicode/Blocks.txt", ranges)
puts_unicode_ranges('tst-reg-parse-unicode', ranges)
# pp ranges
