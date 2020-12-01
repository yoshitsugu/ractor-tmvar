# frozen_string_literal: true

require "ractor/tvar"

class Ractor
  # TMVar for Ractor inspired by Haskell's TMVar based on Ractor::TVar.
  class TMVar
    #
    # represents "empty" value for TMVar
    #
    EMPTY = :RACTOR_TMVAR_EMPTY

    #
    # initialize TMVar
    #
    # @param [Object] value Value to set TVar. It needs to be shareable.
    #
    # @return [TMVar]
    #
    def initialize(value = nil)
      @tvar = Ractor::TVar.new(value)
    end

    #
    # get the value and leave the value to "empty"
    # If the value is already "empty", it will retry the transaction.
    # @note You need to wrap it by Ractor.atomically even if you only call +take+
    #       because +TVar#value=+ needs atomically.
    #
    # @return [Object] value of internal TVar.
    #
    def take
      v = @tvar.value
      raise Ractor::RetryTransaction if v == EMPTY

      @tvar.value = EMPTY
      v
    end

    #
    # try to get the value.
    # If the value is "empty", it returns nil.
    #
    # @return [Object] value of internal TVar, only if exists.
    #
    def try_take
      v = @tvar.value
      return nil if v == EMPTY

      @tvar.value = EMPTY
      v
    end

    #
    # get the value like +take+.
    # The difference between +take+ and +read+ is +take+ leaves the value blank,
    # but +read+ not change the value to blank.
    #
    # @return [Object] value of internal TVar.
    #
    def read
      v = @tvar.value
      raise Ractor::RetryTransaction if v == EMPTY

      v
    end

    #
    # read the value like +read+ but it does not retry.
    #
    # @return [Object] value of internal TVar.
    #
    def try_read
      v = @tvar.value
      v == EMPTY ? nil : v
    end

    #
    # write the given value.
    # If the current value is not "empty", it retries the transaction.
    #
    # @param [Object] new_value neet to be shareable
    #
    def put(new_value)
      raise Ractor::RetryTransaction if @tvar.value != EMPTY

      @tvar.value = new_value
    end

    #
    # try to put value to TVar's value
    # If the value is not "empty", it will not retry and only return false.
    # If it succeed to put, it returns true.
    #
    # @param [Object] new_value neet to be shareable
    #
    def try_put(new_value)
      return false if @tvar.value != EMPTY

      @tvar.value = new_value
      true
    end

    #
    # return the value is "empty" or not.
    #
    # @param [Boolean]
    #
    def empty?
      @tvar.value == EMPTY
    end

    #
    # get the the value like +get+, and replace the value to the given value if the current value is not "empty"
    #
    # @param [Object] new_value neet to be shareable
    #
    def swap(new)
      v = @tvar.value
      raise Ractor::RetryTransaction if v == EMPTY

      @tvar.value = new
      v
    end
  end
end
