# encoding: utf-8

# Common part of regtest
module Regtest::Common
  # Analyzing options
  @@parse_options = nil
  
  # environment variables
  TstConstRetryMax     = (ENV['REGTEST_MAX_RETRY'])?(ENV['REGTEST_MAX_RETRY'].to_i):5
  TstConstRepeatMax    = (ENV['REGTEST_MAX_REPEAT'])?(ENV['REGTEST_MAX_REPEAT'].to_i):32
  TstConstRecursionMax = (ENV['REGTEST_MAX_RECURSION'])?(ENV['REGTEST_MAX_RECURSION'].to_i):32
  TstConstDebug        = (ENV['REGTEST_DEBUG'])?true:false
  TstConstTimeout      = (ENV['REGTEST_TIMEOUT'])?(ENV['REGTEST_TIMEOUT'].to_f):1.0 # default is 1 second
  
  # whole character set if unicode mode. specify as 'ascii|kana', 'ascii|han|kana', etc.
  TstConstUnicodeCharSet  = (ENV['REGTEST_UNICODE_CHAR_SET'] || "ascii|katakana|hiragana").downcase

  # exceptions
  class RegtestTimeout < RuntimeError; end

  # Log
  def TstLog(msg)
    # if(!defined? Rails)  # not output debug message when rails env (even if development mode)
    if TstConstDebug
      warn msg
    end
    # end
  end
  
  # Randomize
  def TstRand(num)
    rand(num)
  end
  
  # Shuffle
  def TstShuffle(array)
    array.shuffle
  end
  
  # Pretty print of matched data object
  def TstMdPrint(md)
    # coloring if tty && (!windows)
    if $stdout.tty? && !RUBY_PLATFORM.downcase.match(/mswin(?!ce)|mingw/)
      "#{md.pre_match.inspect[1..-2]}\e[36m#{md.to_a[0].inspect[1..-2]}\e[0m#{md.post_match.inspect[1..-2]}"
    else
      "#{md.pre_match.inspect[1..-2]} #{md.to_a[0].inspect[1..-2]} #{md.post_match.inspect[1..-2]}"
    end
  end

end

