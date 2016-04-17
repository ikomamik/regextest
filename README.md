# Regtest
Regtest generates sample string that matches with regular expression. It can be used as a debugging tool for regular expression. 

## Installation

Add this line to your application's Gemfile:

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
  /\d{5}/.sample                 #=> "62853"
  /\w{5}/.samples(3)             #=> ["50183", "10646", "35114", "93966", "20186"]
  /(?<=pre)body(?=post)/.sample  #=> "prebodypost"
  /(?<=pre)body(?=post)/.md      #=> #<MatchData "body">
  /\A(?<a>|.|(?:(?<b>.)\g<a>\k<b+0>))\z/.sample  #=> "a]r\\CC\\r]a"
```

## Development

A shell run/regtest to execute/test regtest library.

## Contributing

1. Fork it ( https://bitbucket.org/ikomamik/regtest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
