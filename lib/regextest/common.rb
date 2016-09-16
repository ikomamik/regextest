# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

# Common part of regextest
module Regextest::Common
  # Analyzing options
  @@parse_options = nil
  @@rand_called = false
  
  # environment variables
  TstConstRetryMax     = (ENV['REGEXTEST_MAX_RETRY'])?(ENV['REGEXTEST_MAX_RETRY'].to_i):5
  TstConstRetryMaxSecond = (ENV['REGEXTEST_MAX_RETRY_SECOND'])?(ENV['REGEXTEST_MAX_RETRY_SECOND'].to_f):0.01
  TstConstRepeatMax    = (ENV['REGEXTEST_MAX_REPEAT'])?(ENV['REGEXTEST_MAX_REPEAT'].to_i):32
  TstConstRecursionMax = (ENV['REGEXTEST_MAX_RECURSION'])?(ENV['REGEXTEST_MAX_RECURSION'].to_i):32
  TstConstDebug        = (ENV['REGEXTEST_DEBUG'])?true:false
  TstConstTimeout      = (ENV['REGEXTEST_TIMEOUT'])?(ENV['REGEXTEST_TIMEOUT'].to_f):1.0 # default is 1 second
  TstFixnumMax         = 2 ** 64
  
  # whole character set if unicode mode. specify as 'ascii|kana', 'ascii|han|kana', etc.
  # where "_asciiprint is codepoints range 32..126
  TstConstUnicodeCharSet  = (ENV['REGEXTEST_UNICODE_CHAR_SET'] || "_asciiprint|katakana|hiragana").downcase

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
    @@rand_called = true
    rand(num)
  end
  
  # Shuffle
  def TstShuffle(array)
    @@rand_called = true
    array.shuffle
  end
  
  # reset random_called
  def reset_random_called
    @@rand_called = false
  end
  
  # is_random?
  def is_random?
    @@rand_called
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

