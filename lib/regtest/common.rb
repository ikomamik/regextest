# encoding: utf-8

# Common part of regtest
module Regtest::Common
  # Analyzing options
  @@parse_options = nil
  
  # constants
  TstConstRetryMax =  (ENV['REGTEST_MAX_RETRY'])?(ENV['REGTEST_MAX_RETRY'].to_i):5
  TstConstDebug    =  (ENV['REGTEST_DEBUG'])?true:false

  # Log
  def TstLog(msg)
    # if(!defined? Rails)  # not output debug message when rails env (even if development mode)
    if TstConstDebug
      warn msg
    end
    # end
  end
end

