# Regextest
Regextest generates sample string that matches with regular expression. Unlike similar tools, it recognizes anchors, charactor classes and other advanced notation of ruby regex. Target users are programmers or students for debugging/learning regular expression.

## Installation

You can use [sample application](https://regtestweb.herokuapp.com/test_data/home) without installation. For using at your local machine, add this line to your application's Gemfile:

```ruby
gem 'regextest'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regextest


## Usage

```ruby
require "regextest"

/\d{5}/.sample                   #=> "62853"
5.times.map{/\w{5}/.sample}      #=> ["mCcA5", "1s3Ae", "9HYbe", "x3T0A", "TJHlQ"]
/(?<=pre)body(?=post)/.sample    #=> "prebodypost"
/(?=[a-z])\w{5}(?<=_\d)/.sample  #=> "nCc_0"

/(?<=pre)body(?=post)/.match_data        #=> #<MatchData "body">

palindrome = /\A(?<a>|.|(?:(?<b>.)\g<a>\k<b+0>))\z/
palindrome.sample                #=> "a]r\\CC\\r]a"
palindrome.match_data            #=> #<MatchData "z2#2z" a:"z2#2z" b:"2">
```

## Parameters (environment variables)
- **REGEXTEST_DEBUG**
    - Specify "1" to print verbose debugging information
- **REGEXTEST_MAX_RETRY**
    - Retry count for generation. 5 retry by default.
- **REGEXTEST_MAX_REPEAT**
    - Maximum repeat of element when * or + specified. Default value is 32.
- **REGEXTEST_MAX_RECURSION**
    - Maximum nest of \g<..>. Default value is 32.
- **REGEXTEST_UNICODE_CHAR_SET**
    - Whole character set at unicode mode. Specify unicode char-set names joined with "|". Default value is 'ascii|katakana|hiragana'
- **REGEXTEST_TIMEOUT**
    - Specify timeout second for verifying generated string (by ruby regexp). Default value is 1 second. Note no timeout detected for generating string. It can be used for fuzzering.


## Exceptions
- **Regextest::RegextestError**
    - Impossible to generate string. It is sub-class of standard exception RuntimeError. 
- **Regextest::RegextestFailedToGenerate**
    - Failed to generate string. It is sub-class of standard exception RuntimeError. In many cases, caused by Regextest's restriction)
- **RuntimeError**
    - Bug of Regextest
- **Regextest::RegextestTimeout**
    - Timeout (default is 1 sec) detected while verification. It is sub-class of standard exception RuntimeError. For ignoring verification, you can use sample method with 'verification: false' option.

```ruby
  require "regextest"
  /(1|11){100}$/.sample                       #=> raise Regextest::Common::RegextestTimeout: ...
  /(1|11){100}$/.sample(verification: false)  #=> '11111111...'
```

## Development

  Visit [git repository](https://bitbucket.org/ikomamik/regextest/src) for developing

## Contributing

1. Fork it ( https://bitbucket.org/ikomamik/regextest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Major Bugs/Restrictions
1. Insufficient support of unicode classes
2. Too slow to process regex contains "Han" class
3. Limited support of possesive repeat
4. Limited support of grapheme cluster (\R or \X)

See [issues tracker](https://bitbucket.org/ikomamik/regextest/issues?status=new&status=open) for more detail. 

