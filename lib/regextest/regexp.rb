# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

# Add-on methods (samples, sample, match_data) for Regexp class
# @raise [Regextest::RegextestError] if impossible to generate.
# @raise [Regextest::RegextestFailedToGenerate] if failed to generate. Mainly caused by Regextest's restrictions.
# @raise [Regextest::RegextestTimeout] if detected timeout while verification. Option 'verification: false' may be workaround.
# @raise [RuntimeError] if something wrong... mainly caused by Regextest's bug
class Regexp

  # generate a sample string of regexp
  # @param [Hash] option option parameters for sampling
  # @option option [Fixnum] :seed seed for randomization
  # @option option [TrueClass] :verification specify true (or not speficy) if verified using ruby Regexp.
  # @option option [FalseClass] :verification specify false if skip to verify using ruby Regexp.
  # @return [String] if able to generate matched string
  def sample(option = {})
    if option[:verification] != false
      match_data(option).string
    else
      match_data(option)
    end
  end
  
  # generate match-data object(s) of regexp
  # @param [Hash] option option parameters for sampling
  # @option option [Fixnum] :seed seed for randomization
  # @option option [TrueClass] :verification specify true (or not speficy) if verified using ruby Regexp.
  # @option option [FalseClass] :verification specify false if skip to verify using ruby Regexp.
  # @return [MatchData] if able to generate matched data
  def match_data(option = {})
    regextest = Regextest.new(self, option)
    result = regextest.generate
  end
  
  # parse regexp and return json data
  # @return [String] return parsed json string
  def to_json
    regextest = Regextest.new(self, {})
    regextest.to_json
  end
  
end
