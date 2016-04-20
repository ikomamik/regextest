# encoding: utf-8

require 'regtest'
require 'kconv'
require 'pp'

class Regtest::Test
  def initialize(max_tests = nil)
    results = {
      success: [],
      failed: [],
      others: [],
      not_scope: [],
    }
    do_test(results, max_tests)
    print_results(results)
  end
  
  def print_results(results)
    pp results[:failed]

    puts "======"
    puts "success:   #{results[:success].size}"
    puts "failed:    #{results[:failed].size}"
    puts "others:    #{results[:others].size}"
    puts "not_scope: #{results[:not_scope].size}"
  end
  
  def do_test(results, max_tests)
    get_lines.each_with_index do | line, i |
      break if(max_tests && i >= max_tests)  # for debug
      begin
        puts line
        rc = eval(line)
        if(rc[:result] == :ok)
          results[:success].push({ md: rc[:md], reg: rc[:reg]})
        else
          results[:failed].push({ result: rc })
        end
      rescue RegexpError => ex
        warn "RegexpError #{ex}. \nline:#{line}"
        results[:not_scope].push({result: :regexp_error, message: ex, reg: line})
      rescue ArgumentError => ex
        warn "ArgumentError #{ex}. \nline: line"
        results[:failed].push({result: :argument_error, message: ex, reg: line})
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

  def get_lines
    lines = []
    # py_source = IO.read("../contrib/Onigmo/testpy.py")
    File::open("../contrib/Onigmo/testpy.py") do |f|
      f.each do |line|
        if(md = line.match(/^\s*(?:x|x2|n)\s*\(.+?$/u) rescue nil)
          line.sub!(/,\s*\".+?$/, ")") rescue nil
          lines.push line if line
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

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0
  max_test = ARGV[0] && ARGV[0].to_i
  Regtest::Test.new(max_test)
end
