# frozen_string_literal: true

require "ractor/tvar"
require_relative "tmvar/version"

class Ractor
  # Transactional MVar-like variable for Ractor, inspired by Haskell's
  # +Control.Concurrent.STM.TMVar+ and built on Ractor::TVar.
  #
  # A TMVar is either empty or full. When full it holds a single value.
  # Reading and writing operations are transactional through {Ractor.atomically}.
  #
  # The implementation stores +nil+ when empty and a single-element array +[value]+
  # when full, so any Ruby object (including +nil+) can be stored without colliding
  # with the empty state.
  class TMVar
    #
    # Create a new TMVar.
    #
    # @overload initialize
    #   Creates an empty TMVar (Haskell's +newEmptyTMVar+).
    # @overload initialize(value)
    #   Creates a TMVar filled with +value+ (Haskell's +newTMVar+).
    #   @param [Object] value value to store. With ractor-sharing 0.3, the value is
    #     automatically made Ractor-shareable and the passed object is frozen.
    #     This behavior is provided by the upstream Ractor::TVar, not a TMVar guarantee.
    #
    # @raise [ArgumentError] if more than one argument is given.
    #
    def initialize(*args)
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..1)" if args.size > 1

      @tvar = Ractor::TVar.new(args.empty? ? nil : [args[0]])
    end

    #
    # Create a new TMVar explicitly filled with +value+.
    #
    # This is equivalent to +TMVar.new(value)+ but makes the intent clear when the
    # stored value might be +nil+.
    #
    # @param [Object] value value to store. With ractor-sharing 0.3, the value is
    #   automatically made Ractor-shareable and the passed object is frozen.
    #   This behavior is provided by the upstream Ractor::TVar, not a TMVar guarantee.
    #
    # @return [TMVar]
    #
    def self.new_filled(value)
      new(value)
    end

    #
    # Take the value, leaving the TMVar empty.
    #
    # If the TMVar is empty, the transaction is retried.
    #
    # @note Must be called inside {Ractor.atomically}.
    #
    # @return [Object] the stored value.
    #
    def take
      cell = @tvar.value
      raise Ractor::RetryTransaction if cell.nil?

      @tvar.value = nil
      cell[0]
    end

    #
    # Try to take the value without retrying.
    #
    # If the TMVar is empty, returns +nil+ without calling the block.
    # If the TMVar is full, empties it, yields the value and returns the block's result.
    # Without a block, returns the stored value unchanged.
    # Because the block is called only when full, a stored +nil+ can be told apart
    # from an empty TMVar.
    #
    # @note Must be called inside {Ractor.atomically}.
    #
    # @overload try_take
    #   @return [Object, nil] the stored value, or +nil+ if empty.
    # @overload try_take { |value| ... }
    #   @yieldparam value [Object] the stored value, including +nil+.
    #   @yieldreturn [Object] the value to return from +try_take+.
    #   @return [Object, nil] the block's result, or +nil+ if empty.
    #
    # @example Take a value without a block
    #   tv = Ractor::TMVar.new(5)
    #   Ractor.atomically { tv.try_take } #=> 5
    #   tv.empty? #=> true
    #
    # @example Distinguish a stored nil from an empty TMVar
    #   tv = Ractor::TMVar.new(nil)
    #   Ractor.atomically { tv.try_take { |value| [value] } } #=> [nil]
    #   Ractor.atomically { tv.try_take { |value| [value] } } #=> nil
    #
    def try_take(&block)
      cell = @tvar.value
      return nil if cell.nil?

      @tvar.value = nil
      (block || method(:identity)).call(cell[0])
    end

    #
    # Read the value, leaving the TMVar full.
    #
    # If the TMVar is empty, the transaction is retried.
    # It can also be called outside {Ractor.atomically}.
    #
    # @return [Object] the stored value.
    #
    def read
      cell = @tvar.value
      raise Ractor::RetryTransaction if cell.nil?

      cell[0]
    end

    #
    # Try to read the value without retrying.
    #
    # If the TMVar is empty, returns +nil+ without calling the block.
    # If the TMVar is full, yields the value and returns the block's result.
    # Without a block, returns the stored value unchanged.
    # The TMVar remains full.
    #
    # @note Can be called outside {Ractor.atomically}.
    #
    # @overload try_read
    #   @return [Object, nil] the stored value, or +nil+ if empty.
    # @overload try_read { |value| ... }
    #   @yieldparam value [Object] the stored value, including +nil+.
    #   @yieldreturn [Object] the value to return from +try_read+.
    #   @return [Object, nil] the block's result, or +nil+ if empty.
    #
    # @example Read or transform a value without removing it
    #   tv = Ractor::TMVar.new(5)
    #   tv.try_read #=> 5
    #   tv.try_read { |value| value * 2 } #=> 10
    #   tv.read #=> 5
    #
    # @example Distinguish a stored nil from an empty TMVar
    #   Ractor::TMVar.new(nil).try_read { |value| [value] } #=> [nil]
    #   Ractor::TMVar.new.try_read { |value| [value] } #=> nil
    #
    def try_read(&block)
      cell = @tvar.value
      return nil if cell.nil?

      (block || method(:identity)).call(cell[0])
    end

    #
    # Put a value into the TMVar.
    #
    # If the TMVar is already full, the transaction is retried.
    #
    # @note Must be called inside {Ractor.atomically}.
    #
    # @param [Object] new_value value to store. With ractor-sharing 0.3, the value is
    #   automatically made Ractor-shareable and the passed object is frozen.
    #   This behavior is provided by the upstream Ractor::TVar, not a TMVar guarantee.
    #
    # @return [Object] +new_value+.
    #
    def put(new_value)
      raise Ractor::RetryTransaction unless @tvar.value.nil?

      @tvar.value = [new_value]
      new_value
    end

    #
    # Try to put a value into the TMVar without retrying.
    #
    # @note Must be called inside {Ractor.atomically}.
    #
    # @param [Object] new_value value to store. With ractor-sharing 0.3, the value is
    #   automatically made Ractor-shareable and the passed object is frozen.
    #   This behavior is provided by the upstream Ractor::TVar, not a TMVar guarantee.
    #
    # @return [Boolean] +true+ if the value was stored, +false+ if the TMVar was full.
    #
    def try_put(new_value)
      return false unless @tvar.value.nil?

      @tvar.value = [new_value]
      true
    end

    #
    # Return whether the TMVar is currently empty.
    # It can also be called outside {Ractor.atomically}.
    #
    # @return [Boolean]
    #
    def empty?
      @tvar.value.nil?
    end

    #
    # Replace the stored value and return the previous value.
    #
    # If the TMVar is empty, the transaction is retried.
    #
    # @note Must be called inside {Ractor.atomically}.
    #
    # @param [Object] new_value value to store. With ractor-sharing 0.3, the value is
    #   automatically made Ractor-shareable and the passed object is frozen.
    #   This behavior is provided by the upstream Ractor::TVar, not a TMVar guarantee.
    #
    # @return [Object] the previous value.
    #
    def swap(new_value)
      cell = @tvar.value
      raise Ractor::RetryTransaction if cell.nil?

      @tvar.value = [new_value]
      cell[0]
    end

    private

    def identity(value)
      value
    end
  end
end
