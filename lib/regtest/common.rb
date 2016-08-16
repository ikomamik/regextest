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
  
  # whole character set if unicode mode. specify as 'ascii|kana', 'ascii|han|kana', etc.
  TstConstUnicodeCharSet  = (ENV['REGTEST_UNICODE_CHAR_SET'] || "ascii|katakana|hiragana").downcase

  # Log
  def TstLog(msg)
    # if(!defined? Rails)  # not output debug message when rails env (even if development mode)
    if TstConstDebug
      warn msg
    end
    # end
  end
end

