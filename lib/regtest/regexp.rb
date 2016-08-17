# Add-on methods (samples, sample, match_data) for Regexp class
# @raise [RuntimeError] if something wrong...
# @raise [Regtest::Common::RegtestTimeout] if detected timeout while verification. Option 'verification: false' may be workaround.
class Regexp

  # generate sample strings of regexp
  # @param [Fixnum] num how many samples to be generated
  # @param [Hash] option option parameters for sampling
  # @option option [Fixnum] :seed seed for randomization
  # @option option [TrueClass] :verification specify true (or not speficy) if verified using ruby Regexp.
  # @option option [FalseClass] :verification specify false if skip to verify using ruby Regexp.
  # @return [Array<String>] if able to generate matched string
  # @return [nil] if failed to generate matched string
  def samples(num = 1, option = {})
    if num == 1
      sample(option)
    else
      if option[:verification] != false
        match_data(num, option).map{|elem| elem.string}
      else
        match_data(num, option)
      end
    end
  end
  
  # generate a sample string of regexp
  # @param [Hash] option option parameters for sampling
  # @option option [Fixnum] :seed seed for randomization
  # @option option [TrueClass] :verification specify true (or not speficy) if verified using ruby Regexp.
  # @option option [FalseClass] :verification specify false if skip to verify using ruby Regexp.
  # @return [String] if able to generate matched string
  # @return [nil] if failed to generate matched string
  def sample(option = {})
    if option[:verification] != false
      match_data(1, option).string
    else
      match_data(1, option)
    end
  end
  
  # generate match-data object(s) of regexp
  # @param [Fixnum] num how many samples to be generated
  # @param [Hash] option option parameters for sampling
  # @option option [Fixnum] :seed seed for randomization
  # @option option [TrueClass] :verification specify true (or not speficy) if verified using ruby Regexp.
  # @option option [FalseClass] :verification specify false if skip to verify using ruby Regexp.
  # @return [Array<MatchData>] if num > 1, returns array of matched data. The array may contain nil if failed to generate
  # @return [MatchData] if num == 1 and able to generate matched data
  # @return [nil] if num == 1 and failed to generate matched data
  def match_data(num = 1, option = {})
    regtest = Regtest.new(self, option)
    if num == 1
      result = regtest.generate
    else
      result = num.times.inject([]){|array| array.push regtest.generate}
    end
  end
  
end
