# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest'
require 'kconv'
require 'timeout'
require 'pp'
require 'csv'

class Regextest::Test
  def initialize(min_test, max_test)
    @csv_file = "test_history.csv"
    @results = {
      success: [],
      bug: [],
      failed: [],
      impossible: [],
      others: [],
      not_scope: [],
      timeout: [],
      perl_syntax: [],
    }
    time_out = 2
    do_test(@results, min_test, max_test, time_out)
  end
  
  def append_to_csv(results = @results)
    results2 = []
    results.each do | key, values |
      values.each do | value |
        value[:reason] = key
        results2.push value
      end
    end
    results2.sort!{|x, y| x[:index] <=> y[:index]}
    if FileTest.exist?(@csv_file)
      old_data = CSV.read(@csv_file, "rb:UTF-8")
      CSV.open(@csv_file, "wb:UTF-8") do |csv|
        csv << (old_data.shift) + [Time.now.to_s]
        results2.each do | result |
          old_row = old_data.shift
          break if !old_row || old_row.size == 0
          regex = result[:test] || result[:reg]
          if old_row[0].to_i != result[:index]
            raise "regex not matched. csv: #{old_row}, new: #{result}"
          end
          csv << old_row + [result[:reason]]
        end
      end
    else
      CSV.open(@csv_file, "wb:UTF-8") do |csv|
        csv << ["ID", "REGEXP", Time.now.to_s]
        results2.each do | result |
          regex = result[:test] || result[:reg]
          csv << [result[:index], regex, result[:reason]]
        end
      end
    end
  end
  
  def print_results(results = @results)
    puts ""
    (results[:failed] + results[:bug]).each do | failed_hash |
      regex = failed_hash[:reg] || failed_hash[:result][:reg]
      puts "======="
      puts "  type: #{failed_hash[:type] || failed_hash[:result][:result]}"
      puts "  test: #{regex}"
      puts "  info: #{failed_hash[:info] || failed_hash[:result][:reason]}"
      puts "  indx: #{failed_hash[:index]}"
      pp failed_hash
    end

    puts "======"
    puts "success:    #{results[:success].size}"
    puts "bug:        #{results[:bug].size}"
    puts "failed:     #{results[:failed].size}"
    puts "impossible: #{results[:impossible].size}"
    puts "others:     #{results[:others].size}"
    puts "timeout:    #{results[:timeout].size}"
    puts "regexp error: #{results[:not_scope].size}"
    puts "perl_syntax:  #{results[:perl_syntax].size}"
  end
  
  def do_test(results, min_test, max_test, timeout_seconds)
    get_lines(results).each_with_index do | line, i |
      next if(i < min_test || i > max_test)
      puts line
      reg = line.gsub(/^\s*(?:x1|x2|n)\(\"|\"\)\s*$/, "")
      begin
        rc = nil
        timeout(timeout_seconds){
          rc = eval(line)
        }
        if(rc[:result] == :ok)
          results[:success].push({ md: rc[:md], reg: rc[:reg], index: i})
        else
          results[:failed].push({ result: rc, index: i })
        end
      rescue Timeout::Error => ex
        warn "Timeout::Error #{ex}. \nline:#{line}"
        results[:timeout].push({result: :timeout, message: ex, reg: reg, index: i})
      rescue RegexpError => ex
        warn "RegexpError #{ex}. \nline:#{line}"
        results[:not_scope].push({result: :regexp_error, message: ex, reg: reg, index: i})
      rescue ArgumentError => ex
        warn "ArgumentError #{ex}. \nline: line"
        results[:failed].push({type: :argument_error, info: ex, reg: reg, index: i})
      #rescue Regextest::Common::RegextestTimeout => ex
      #  warn "RegextestTimeout #{ex}. \nline:#{line}"
      #  results[:failed].push({ type: :timeout, reg: reg, info: ex, index: i})
      rescue Regextest::RegextestError => ex
        warn "RegextestError #{ex}. \nline:#{line}"
        results[:impossible].push({ type: Regextest::RegextestError, reg: reg, info: ex, index: i})
      rescue Regextest::RegextestFailedToGenerate => ex
        warn "RegextestFailedToGenerate #{ex}. \nline:#{line}"
        results[:failed].push({ type: Regextest::RegextestFailedToGenerate, reg: reg, info: ex, index: i})
      rescue RuntimeError => ex
        warn "RuntimeError #{ex}. \nline:#{line}"
        results[:bug].push({ type: RuntimeError, reg: reg, info: ex, index: i})
      rescue SyntaxError => ex
        warn "SyntaxError #{ex}. \nline:#{line}"
        results[:failed].push({ type: SyntaxError, reg: reg, info: ex, index: i})
      rescue NameError => ex
        warn "NameError #{ex}. \nline:#{line}"
        results[:failed].push({ type: NameError, reg: reg, info: ex, index: i})
      rescue TypeError => ex
        warn "TypeError #{ex}. \nline:#{line}"
        results[:failed].push({ type: TypeError, reg: reg, info: ex, index: i})
      rescue Encoding::CompatibilityError => ex
        warn "Encoding::CompatibilityError #{ex}. \nline:#{line}"
        results[:failed].push({ type: Encoding::CompatibilityError, reg: reg, info: ex, index: i})
      end
    end
  end

  def get_lines(results)
    lines = []
    perl_index = 9000
    # py_source = IO.read("../contrib/Onigmo/testpy.py")
    File::open("../contrib/Onigmo/testpy.py") do |f|
      f.each do |line|
        line.force_encoding("utf-8")
        if !line.match(/ONIG_SYNTAX_PERL/)
          if(md = line.match(/^\s*(?:x|x2|n)\s*\(.+?$/u) rescue nil)
            line.sub!(/,\s*\".+?$/, ")") rescue nil
            lines.push line if line
          end
        else
          warn "Perl syntax. \nline:#{line}"
          results[:perl_syntax].push({ type: :perl_syntax, test: line, info: nil, index: perl_index})
          perl_index += 1
        end
      end
    end
    lines
  end

  def check_normal_test(reg)
    result = nil
    a_test = /#{reg}/
    # puts a_test.source
    obj = Regextest.new(a_test)
    10.times do | i |
      md = obj.generate
      if(md)
        # print "OK md:#{md},"
        result = {result: :ok, md: md, reg: a_test}
      else
        warn "Failed. reg='#{a_test}', reason=#{obj.reason}"
        result = {result: :unmatched, reg: a_test, reason: obj.reason}
        break
      end
    end
    result
  end

  def x(reg, *params)
    check_normal_test(reg)
  end

  def x2(reg, *params)
    check_normal_test(reg)
  end

  def n(reg, *params)
    check_normal_test(reg)
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
  if ARGV.size == 0 || ARGV[0].match(/^\d+$/)
    min_test = ARGV[1]?(ARGV[0].to_i):0
    max_test = ARGV[1]?(ARGV[1].to_i):(ARGV[0]?(ARGV[0].to_i):99999999)
    test_obj = Regextest::Test.new(min_test, max_test)
    test_obj.print_results
  elsif ARGV[0] == "csv"
    test_obj = Regextest::Test.new(0, 99999999)
    test_obj.print_results
    test_obj.append_to_csv
  end
end
