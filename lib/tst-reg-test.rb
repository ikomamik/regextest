# encoding: utf-8

require 'regtest'
require 'kconv'
require 'timeout'
require 'pp'

class Regtest::Test
  def initialize(max_tests = nil)
    results = {
      success: [],
      failed: [],
      others: [],
      not_scope: [],
      timeout: [],
      perl_syntax: [],
    }
    time_out = 1
    do_test(results, max_tests, time_out)
    print_results(results)
  end
  
  def print_results(results)
    puts ""
    results[:failed].each do | failed_hash |
      puts "======="
      puts "  type: #{failed_hash[:type] || failed_hash[:result][:result]}"
      puts "  test: #{failed_hash[:test] || failed_hash[:result][:reg]}"
      puts "  info: #{failed_hash[:info] || failed_hash[:result][:reason]}"
      # pp failed_hash
    end

    puts "======"
    puts "success:   #{results[:success].size}"
    puts "failed:    #{results[:failed].size}"
    puts "others:    #{results[:others].size}"
    puts "not_scope: #{results[:not_scope].size}"
    puts "timeout:   #{results[:timeout].size}"
    puts "perl_syntax:   #{results[:perl_syntax].size}"
  end
  
  def do_test(results, max_tests, timeout_seconds)
    get_lines(results).each_with_index do | line, i |
      break if(max_tests && i >= max_tests)  # for debug
      puts line
      begin
        rc = nil
        timeout(timeout_seconds){
          rc = eval(line)
        }
        if(rc[:result] == :ok)
          results[:success].push({ md: rc[:md], reg: rc[:reg]})
        else
          results[:failed].push({ result: rc })
        end
      rescue Timeout::Error => ex
        warn "Timeout::Error #{ex}. \nline:#{line}"
        results[:timeout].push({result: :timeout, message: ex, reg: line})
      rescue RegexpError => ex
        warn "RegexpError #{ex}. \nline:#{line}"
        results[:not_scope].push({result: :regexp_error, message: ex, reg: line})
      rescue ArgumentError => ex
        warn "ArgumentError #{ex}. \nline: line"
        results[:failed].push({type: :argument_error, info: ex, test: line})
      rescue RuntimeError => ex
        warn "RuntimeError #{ex}. \nline:#{line}"
        results[:failed].push({ type: RuntimeError, test: line, info: ex})
      rescue SyntaxError => ex
        warn "SyntaxError #{ex}. \nline:#{line}"
        results[:failed].push({ type: SyntaxError, test: line, info: ex})
      rescue NameError => ex
        warn "NameError #{ex}. \nline:#{line}"
        results[:failed].push({ type: NameError, test: line, info: ex})
      rescue Encoding::CompatibilityError => ex
        warn "Encoding::CompatibilityError #{ex}. \nline:#{line}"
        results[:failed].push({ type: Encoding::CompatibilityError, test: line, info: ex})
      end
    end
  end

  def get_lines(results)
    lines = []
    # py_source = IO.read("../contrib/Onigmo/testpy.py")
    File::open("../contrib/Onigmo/testpy.py") do |f|
      f.each do |line|
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
    puts a_test.source
    obj = Regtest.new(a_test)
    10.times do | i |
      md = obj.generate
      if(md)
        print "OK md:#{md},"
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
  max_test = ARGV[0] && ARGV[0].to_i
  Regtest::Test.new(max_test)
end
