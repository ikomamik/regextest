# encoding: utf-8

# Predefined (built-in) functions
class Regtest::Front::BuiltinFunctions
  def initialize()
    @functions = set_functions
  end
    
  # find a built-in function
  def find_func(function_name)
    pp @functions
    @functions[function_name]
  end
  
  # set built-in functions
  def set_functions
    hash = {
      '_day_' => '(?<__day_year>20(?:(?<__day_leap_year>[02468][048]|[13579][26])|\d\d)){0}(?<__day_month>(?<__day_day31>0?[13578]|1[02])|(?<__day_day30>0?[469]|11)|(?<__day_dayfeb>0?2)){0}(?<__day_day>1\d|(?(<__day_day30>)(?:2\d|30)|(?(<__day_day31>)(?:2\d|3[01])|(?(<__day_leap_year>)2\d|2[0-8])))|0?[1-9]){0}(?<__day_delim>\/){0}(?<_day_>\g<__day_year>\g<__day_delim>\g<__day_month>\g<__day_delim>\g<__day_day>){0}',
      '_jp_fname_' => '(?<_jp_fname_>太郎|花子){0}',
      '_jp_lname_' => '(?<_jp_lname_>山田|佐藤){0}',
      '_fname_' => '(?<_fname_>Joe|Alice){0}',
      '_lname_' => '(?<_lname_>Smith|Brown){0}',
    }
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

