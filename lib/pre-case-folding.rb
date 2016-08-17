# encoding: utf-8

require "pp"

# A script for generating case-folding of Unicode
# This uses tables of Unicode.org, i.e.  

class RegextestPreCaseFolding
  def self.generate(input_file, output_file)
    # Get valid casefoldings from unicode table
    case_foldings = read_unicode_case_folding("./contrib/unicode/CaseFolding.txt")
    puts_unicode_case_folding('lib/regextest/front/case-folding.rb', case_foldings)
  end

  # Get list of case-folding pairs from Unicode.org table
  def self.read_unicode_case_folding(file)
    case_foldings = {}
    read_unicode_line(file) do | line |
      if md = line.match(/^(\h{4,6});\s*([CFST]); ([ \h]+);/)
        code_point = md[1].to_i(16)
        mapping = md[3].split(" ").map{|elem| elem.to_i(16)}
        code_point_string = [code_point].pack("U*")
        mapping_string = mapping.map{|elem| [elem].pack("U*")}.join("")
        if /(?ai:#{code_point_string})/.match(mapping_string)
          case_foldings[[code_point]] ||= []
          case_foldings[[code_point]].push mapping
          case_foldings[mapping] ||= []
          case_foldings[mapping].push [code_point]
        else
          # puts "code=#{code_point_string}, map=#{mapping_string}"
        end
      else
        raise "not matched line: #{line}"
      end
    end
    # case_foldings.each do | key, value |
    #   value.each do | elem |
    #     puts "#{key.pack("U*")} #{key}: #{elem.pack("U*") } #{elem}"
    #   end
    # end
    case_foldings
  end

  # common process for parsing tables of Unicode.org
  def self.read_unicode_line(file)
    content = open(file, 'r:BOM|UTF-8') {|f| f.read}  # ignore BOM header
    content.split(/\r?\n/).each do | line |
      next if(line.length == 0 || line[0..0] == '#')
      yield(line)
    end
  end

  # puts source to unicode.rb
  def self.puts_unicode_case_folding(case_folding_file, case_folding)
    
    template =<<"    END_OF_TEMPLATE"
      # encoding: utf-8
      # DO NOT Modify This File Since Automatically Generated

      # Range of Unicode
      class Regextest::Front::CaseFolding
        # return case foldings
        def self.ignore_case(letter_array)
          CASE_FOLDING_HASH[letter_array]
        end
        
        # case folding hash [codepoint] => [[mapping_1], ...]
        CASE_FOLDING_HASH =
#{case_folding.inspect}
      end

      # Test suite (execute when this file is specified in command line)
      if __FILE__ == $0 
      end
    END_OF_TEMPLATE
    template.gsub!(/^      /, "")
    File.open(case_folding_file, "w") do |fp|
      fp.puts template
    end
    
  end
end

input_file  = "./contrib/unicode/CaseFolding.txt"
output_file = "./lib/regextest/front/case-folding.rb"


RegextestPreCaseFolding.generate(input_file, output_file)

# test code
require "regextest"
require "#{output_file}"

if Regextest::Front::CaseFolding.ignore_case([65]) == [[97]]
  puts "OK"
else
  puts "NG"
  exit(1)
end
