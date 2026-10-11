# Ractor::TMVar

TMVar for Ractor inspired by [Haskell's TMVar](https://hackage.haskell.org/package/stm-2.5.0.0/docs/Control-Concurrent-STM-TMVar.html) based on [Ractor::TVar](https://github.com/ko1/ractor-sharing/blob/main/docs/tvar.md).

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

```ruby
require 'ractor/tmvar'

tv1 = Ractor::TMVar.new(0)
tv2 = Ractor::TMVar.new(0)
rs = 100.times.map do
  Ractor.new tv1, tv2 do |v1, v2|
    value1 = nil
    value2 = nil
    Ractor.atomically do
      # take value like takeTMVar in Haskell
      value1 = v1.take
      value2 = v2.take
    end
    Ractor.atomically do
      # set value like putTMVar in Haskell
      v2.put(value2 + 2)
      v1.put(value1 + 1)
    end
  end
end
rs.each(&:value)

tv1.read #=> 100
tv2.read #=> 200
```

`Ractor::TMVar.new` creates an empty variable, while `Ractor::TMVar.new(value)` or
`Ractor::TMVar.new_filled(value)` creates a variable already containing `value`.
`nil` can be stored as a normal value:

```ruby
tv = Ractor::TMVar.new_filled(nil)
tv.empty? #=> false
tv.read   #=> nil
```

### Transactional operations

`take`, `put`, `swap`, `try_take`, and `try_put` must be called inside `Ractor.atomically`. `read` and
`empty?` can be called outside of a transaction.

```ruby
tv = Ractor::TMVar.new
Ractor.atomically { tv.put(42) }
Ractor.atomically { tv.take } #=> 42
```

### Non-blocking try operations

`try_take` and `try_read` never retry. Without a block, they return the stored
value, or `nil` when empty. With a block, when the variable is
empty they return `nil` without calling the block. When it is full they yield the
stored value and return the block's result, so a stored `nil` can be told apart
from an empty variable. `try_take` empties the variable before yielding;
`try_read` leaves it full.

```ruby
tv = Ractor::TMVar.new(5)

tv.try_read { |v| v * 2 } #=> 10
tv.read                   #=> 5

Ractor.atomically { tv.try_take { |v| v * 2 } } #=> 10
tv.empty?                                        #=> true

empty = Ractor::TMVar.new
Ractor.atomically { empty.try_take { |v| [v] } } #=> nil (block not called)

filled_with_nil = Ractor::TMVar.new_filled(nil)
filled_with_nil.try_read { |v| [v] } #=> [nil]
```

`try_put` returns `true` when it stored the value and `false` when the variable
was already full.

```ruby
tv = Ractor::TMVar.new
Ractor.atomically { tv.try_put(1) } #=> true
Ractor.atomically { tv.try_put(2) } #=> false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yoshitsugu/ractor-tmvar.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
