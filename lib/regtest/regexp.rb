class Regexp

  # generate sample strings of regexp
  def samples(num = 1, option = {})
    if num == 1
      sample(option)
    else
      match_data(num, option).map{|elem| elem.string}
    end
  end
  
  # generate a sample string of regexp
  def sample(option = {})
    match_data.string
  end
  
  # generate match-data object(s) of regexp
  def match_data(num = 1, option = {})
    regtest = Regtest.new(self, option)
    if num == 1
      result = regtest.generate
    else
      result = num.times.inject([]){|array| array.push regtest.generate}
    end
  end
  
end
