# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest'
require 'kconv'
require 'timeout'
require 'pp'

class Regextest::Test
  def initialize(min_test, max_test)
    results = {
      success: [],
      failed: [],
      others: [],
      not_scope: [],
      timeout: [],
      perl_syntax: [],
    }
    time_out = 1
    do_test(results, min_test, max_test, time_out)
    print_results(results)
  end
  
  def print_results(results)
    puts ""
    exceptions = get_exceptions
    ignore = 0
    results[:failed].each do | failed_hash |
      regex = failed_hash[:test] || failed_hash[:result][:reg]
      if !exceptions[regex]
        puts "======="
        puts "  type: #{failed_hash[:type] || failed_hash[:result][:result]}"
        puts "  test: #{regex}"
        puts "  info: #{failed_hash[:info] || failed_hash[:result][:reason]}"
        puts "  indx: #{failed_hash[:index]}"
        pp failed_hash
      else
        ignore += 1
      end
    end

    puts "======"
    puts "success:   #{results[:success].size}"
    puts "failed:    #{results[:failed].size - ignore}"
    puts "ignore:    #{ignore}"
    puts "others:    #{results[:others].size}"
    puts "timeout:   #{results[:timeout].size}"
    puts "regexp error: #{results[:not_scope].size}"
    puts "perl_syntax:  #{results[:perl_syntax].size}"
  end
  
  def do_test(results, min_test, max_test, timeout_seconds)
    get_lines(results).each_with_index do | line, i |
      next if(i < min_test || i > max_test)
      puts line
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
        results[:timeout].push({result: :timeout, message: ex, reg: line, index: i})
      rescue RegexpError => ex
        warn "RegexpError #{ex}. \nline:#{line}"
        results[:not_scope].push({result: :regexp_error, message: ex, reg: line, index: i})
      rescue ArgumentError => ex
        warn "ArgumentError #{ex}. \nline: line"
        results[:failed].push({type: :argument_error, info: ex, test: line, index: i})
      #rescue Regextest::Common::RegextestTimeout => ex
      #  warn "RegextestTimeout #{ex}. \nline:#{line}"
      #  results[:failed].push({ type: :timeout, test: line, info: ex, index: i})
      rescue RuntimeError => ex
        warn "RuntimeError #{ex}. \nline:#{line}"
        results[:failed].push({ type: RuntimeError, test: line, info: ex, index: i})
      rescue SyntaxError => ex
        warn "SyntaxError #{ex}. \nline:#{line}"
        results[:failed].push({ type: SyntaxError, test: line, info: ex, index: i})
      rescue NameError => ex
        warn "NameError #{ex}. \nline:#{line}"
        results[:failed].push({ type: NameError, test: line, info: ex, index: i})
      rescue TypeError => ex
        warn "TypeError #{ex}. \nline:#{line}"
        results[:failed].push({ type: TypeError, test: line, info: ex, index: i})
      rescue Encoding::CompatibilityError => ex
        warn "Encoding::CompatibilityError #{ex}. \nline:#{line}"
        results[:failed].push({ type: Encoding::CompatibilityError, test: line, info: ex, index: i})
      end
    end
  end

  def get_lines(results)
    lines = []
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
          results[:perl_syntax].push({ type: :perl_syntax, test: line, info: nil})
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

def get_exceptions
  {
    /az\G/  => true,
    /az\A/  => true,
    /a\Az/  => true,
    /とて\G/  => true,
    /まみ\A/  => true,
    /ま\Aみ/  => true,
  }
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
  min_test = ARGV[1]?(ARGV[0].to_i):0
  max_test = ARGV[1]?(ARGV[1].to_i):(ARGV[0]?(ARGV[0].to_i):99999999)
  Regextest::Test.new(min_test, max_test)
end
