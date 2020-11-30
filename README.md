# Ractor::TMVar

TMVar for Ractor inspired by [Haskell's TMVar](https://hackage.haskell.org/package/stm-2.5.0.0/docs/Control-Concurrent-STM-TMVar.html) based on [Ractor::TVar](https://github.com/ko1/ractor-tvar).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ractor-tmvar'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ractor-tmvar

## Usage

Please see [Ractor::TVar](https://github.com/ko1/ractor-tvar) before using this.  
Now we have only `value` and `value=` operations.

```ruby
require 'ractor-tmvar'

tv1 = Ractor::TMVar.new(0)
tv2 = Ractor::TMVar.new(0)
rs = 100.times.map do
  Ractor.new tv1, tv2 do |v1, v2|
    value1 = nil
    value2 = nil
    Ractor.atomically do
      # take value similar to takeTMVar in Haskell
      value1 = v1.value
      value2 = v2.value
    end
    Ractor.atomically do
      # set value similar to putTMVar in Haskell
      v2.value = value2 + 2
      v1.value = value1 + 1
    end
  end
end
rs.each(&:take)
assert_equal 100, tv1.value
assert_equal 200, tv2.value
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yoshitsugu/ractor-tmvar.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
