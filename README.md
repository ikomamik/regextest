# Regtest
Regtest generates sample string that matches with regular expression. Unlike similar tools, it recognizes anchors, charactor classes and other advanced notation of ruby regex. Target users are programmers or students for debugging/learning regular expression.

## Installation

You can use [sample application](https://regtestweb.herokuapp.com/test_data/home) without installation. For using at your local machine, add this line to your application's Gemfile:

```ruby
gem 'regtest'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regtest


## Usage

```ruby
  require "regtest"
  /\d{5}/.sample                   #=> "62853"
  /\w{5}/.samples(3)               #=> ["50183", "10646", "35114", "93966", "20186"]
  /(?<=pre)body(?=post)/.sample    #=> "prebodypost"
  /(?=[a-z])\w{5}(?<=_\d)/.samples(4)      #=> ["nCc_0", "nxP_6", "cMl_3", "riQ_9"]
  
  /(?<=pre)body(?=post)/.match_data        #=> #<MatchData "body">
  
  palindrome = /\A(?<a>|.|(?:(?<b>.)\g<a>\k<b+0>))\z/
  palindrome.sample                #=> "a]r\\CC\\r]a"
  palindrome.match_data            #=> #<MatchData "z2#2z" a:"z2#2z" b:"2">
```

## Parameters (environment variables)
<dl>
  <dt>REGTEST_DEBUG</dt>
    <dd>Specify "1" to print verbose debugging information</dd>
  <dt>REGTEST_MAX_RETRY</dt>
    <dd>Retry count for generation. 5 retry by default.</dd>
  <dt>REGTEST_MAX_REPEAT</dt>
    <dd>Maximum repeat of element when * or + specified. Default value is 32.</dd>
  <dt>REGTEST_MAX_RECURSION</dt>
    <dd>Maximum nest of \g<..>. Default value is 32.</dd>
  <dt>REGTEST_UNICODE_CHAR_SET</dt>
    <dd>Whole character set at unicode mode. Specify unicode char-set names joined with "|". Default value is 'ascii|katakana|hiragana'</dd>
  <dt>REGTEST_TIMEOUT</dt>
    <dd>Specify timeout second for verifying generated string (by ruby regexp). Default value is 1 second. Note no timeout detected for generating string. It can be used for fuzzering.</dd>
</dl>


## Exceptions
<dl>
  <dt>Regtest::Common::REGTEST_TIMEOUT</dt>
    <dd>Timeout detected while verification. It is sub-class of standard exception RuntimeError. For ignoring verification, you can use sample method with 'verification: false' option.
    </dd>
</dl>
```ruby
  require "regtest"
  /(1|11){100}$/.sample                       #=> raise Regtest::Common::RegtestTimeout: ...
  /(1|11){100}$/.sample(verification: false)  #=> '11111111...'
```

## Development

  Visit [git repository](https://bitbucket.org/ikomamik/regtest/src) for developing

## Contributing

1. Fork it ( https://bitbucket.org/ikomamik/regtest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Major Bugs/Restrictions
1. Insufficient support of unicode classes
2. Too slow to process regex contains "Han" class
3. Limited support of possesive repeat
4. Limited support of grapheme cluster (\R or \X)

See [issues tracker](https://bitbucket.org/ikomamik/regtest/issues?status=new&status=open) for more detail. 

