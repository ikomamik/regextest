# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require "pp"

# A script for generating character class of Unicode
# It does not use tables of Unicode.org, 
# but use result of Ruby Regexp execution

class RegextestPreUnicode
  def self.generate
    # Get valid properties of Ruby
    onig_properties = read_onig_properties("./contrib/Onigmo/UnicodeProps.txt")
    ranges = get_ranges_of_properties(onig_properties)
    puts_unicode_ranges('lib/regextest/unicode.rb', ranges)
  end

  # Get list of Unicode classes from Onigmo manual
  def self.read_onig_properties(file)
    content = IO.read(file)
    class_name = nil
    properties = {}
    content.split(/\r?\n/).each_with_index do | line, i |
      # Type or property
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
        # Somehow some property name fails. ignore as for now
        warn "Regexp error at /\\p{#{prop_name}}/"
      end
      
      # for debugging
      # break if(i > 10)
    end
    properties
  end

  # output ruby source (using TRange) corresponding to scripts/blocks of Unicode
  def self.get_ranges_of_properties(properties)
    puts "\nGenerating Unicode table. It takes 1-2 minutes."
    ranges = {}
    
    # form whole letter to array, then join all letters
    # (concatinating string cause performance problem)
    whole_letters_array = []
    0.step(0x10ffff).each do | codepoint |
      # skip surrogate part
      next if (codepoint >= 0xd800 && codepoint <= 0xdfff)
      whole_letters_array.push  [codepoint].pack("U*")
    end
    whole_letters = whole_letters_array.join("")

    # scan string generated for each class
    properties.each do | prop_name, value |
      whole_letters.scan(value[:reg]) do | matched |
        
        value[:ranges].push (matched[0].unpack("U*")[0]..matched[-1].unpack("U*")[0])
      end
      # puts "#{prop_name}: #{value}"
      ranges[prop_name] = value[:ranges]
    end
    ranges
  end

  # puts source to unicode.rb
  def self.puts_unicode_ranges(unicode_file, ranges)
    ranges_source = ranges.keys.map { |prop_name|
      (" "*14) + "when \"#{prop_name}\"\n" +
      (" "*16) + "([" +
      ( ranges[prop_name].map{|range| "[#{range.begin}, #{range.end}]"}.join(", ") ) +
      "])"
    }.join("\n")
    
    template =<<"    END_OF_TEMPLATE"
      # encoding: utf-8
      # DO NOT Modify This File Since Automatically Generated

      # Range of Unicode
      class Regextest::Unicode
        # Generate hash of properties
        def self.property(class_name)
          case class_name.downcase
          # Regextest defined char classes (from underscore)
          when "_asciiprint"
            ([[32, 126]])
            
          # Unicode.org defined char classes
#{ranges_source}
          else
            warn "Class name (#\{class_name\}) not found. Ignored."
            []
          end
        end
        
        # enumerate char-set
        def self.enumerate(class_name)
          self.property(class_name).inject([]){|result,elem| result += (elem[0]..elem[1]).to_a}
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

RegextestPreUnicode.generate
