# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest'
require 'kconv'
require 'timeout'
require 'pp'

class Regextest::Test
  def initialize
    time_out = 1
    results = do_test(time_out)
    @spec_file = "spec/regression_spec.rb"
    puts_spec(@spec_file, results)
    
  end
  
  def do_test(timeout_seconds)
    results = []
    get_lines(timeout_seconds).each_with_index do | line, i |
      begin
        warn line
        eval(line)
      rescue SyntaxError => ex
        warn "EVAL ERROR: #{ex}, #{line}"
        results.push({
          explain: "raises #{ex}, when eval (#{line})",
          expect:  "eval(#{line})",
          raises:   "#{ex.class}"
        })
      end
    end
    results
  end
  
  def puts_spec(spec_file, results)
    File.open(spec_file, "w") do |fp|
      fp.puts "require 'spec_helper'"
      fp.puts "describe Regextest do"
      results.each do | result |
        fp.puts "  it '#{result[:explain]}' do"
        if result[:to_be]
          fp.puts "    expect(#{result[:expect]}).to be_a(#{result[:to_be]})"
        elsif result[:raises]
          fp.puts "    expect {#{result[:expect]}}.to raise_error(#{result[:raises]})"
        else
          raise "Invalid result: #{result}"
        end
        fp.puts "  end"
      end
      fp.puts "end"
    end
  end

  def get_lines(timeout_seconds)
    lines = []
    # py_source = IO.read("./contrib/Onigmo/testpy.py")
    File::open("./contrib/Onigmo/testpy.py") do |f|
      f.each.with_index do |line, line_num|
        break if line_num > 400
        line.force_encoding("utf-8")
        if !line.match(/ONIG_SYNTAX_PERL/)
          if(md = line.match(/^\s*(?:x|x2|n)\s*\(.+?$/u) rescue nil)
            line.sub!(/,\s*\".+?$/, ", results, timeout_seconds)") rescue nil
            lines.push line if line
          end
        else
          warn "Perl syntax. \nline:#{line}"
        end
      end
    end
    lines
  end

  def check_normal_test(reg, results, timeout_seconds)
    result = nil
    a_test = /#{reg}/
    timeout(timeout_seconds) do
      10.times do | i |
        md = a_test.match_data(seed: i)
        if(md)
          # print "OK md:#{md},"
          result = {
            explain: "can parse (#{reg}) and generate match-data",
            expect:  "/#{reg}/.match_data",
            to_be:   "MatchData"
          }
        else
          warn "Failed. reg='#{a_test}', reason=#{obj.reason}"
          result = {
            explain: "cannot parse / generate (#{reg})",
            expect:  "/#{reg}/.match_data",
            to_be:   "Nil"
          }
          break
        end
      end
    end
    results.push result
  rescue => ex
    warn "#{ex}"
    results.push({
      explain: "raises #{ex}, when parse / generate (#{reg})",
      expect:  "/#{reg}/.match_data",
      raises:   "#{ex.class}"
    })
  end

  def x(reg, *params)
    check_normal_test(reg, *params)
  end

  def x2(reg, *params)
    check_normal_test(reg, *params)
  end

  def n(reg, *params)
    check_normal_test(reg, *params)
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
  Regextest::Test.new
end
