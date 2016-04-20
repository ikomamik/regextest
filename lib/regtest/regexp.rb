class Regexp

  # generate sample strings of regexp
  def samples(num=1)
    if num == 1
      sample
    else
      match_data(num).map{|elem| elem.string}
    end
  end
  
  # generate a sample string of regexp
  def sample
    match_data.string
  end
  
  # generate match-data object(s) of regexp
  def match_data(num=1)
    regtest = Regtest.new(self)
    if num == 1
      result = regtest.generate
    else
      result = []
      num.times do
        result.push regtest.generate
      end
    end
    result
  end
  
end
