# frozen_string_literal: true

require "ractor/tvar"

class Ractor
  # TMVar for Ractor inspired by Haskell's TMVar based on Ractor::TVar.
  class TMVar
    #
    # Represents "blank" value for TMVar
    #
    BLANK = :RACTOR_TMVAR_BLANK

    #
    # TMVar.new(value) to initialize TMVar
    #
    # @param [Object] tvar neet to be shareable
    #
    # @return [TMVar]
    #
    def initialize(tvar = nil)
      @tvar = Ractor::TVar.new(tvar)
    end

    #
    # Get TVar's value and leave the value to "blank".
    # If the value is already "blank", it will retry the transaction.
    #
    # @return [Object] value of internal TVar.
    #
    def value
      v = @tvar.value
      raise Ractor::RetryTransaction if v == BLANK

      # NOTE: TVar cannot be set without `Ractor.atomically`.
      Ractor.atomically do
        @tvar.value = BLANK
      end
      v
    end

    #
    # Put value to TVar's value.
    # If the value is not "blank", it will retry the transaction.
    #
    # @param [Object] new_value neet to be shareable
    #
    def value=(new_value)
      raise Ractor::RetryTransaction if @tvar.value != BLANK

      @tvar.value = new_value
    end
  end
end
