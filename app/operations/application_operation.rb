require 'dry/operation'
require 'dry/operation/extensions/active_record'

class ApplicationOperation < Dry::Operation
  # Provides `transaction do ... end` inside `call` for atomic
  # multi-write steps
  include Dry::Operation::Extensions::ActiveRecord[requires_new: true]

  class << self
    # Per-operation contract DSL:
    #
    #   contract do
    #     params { required(:account).filled(Types::Account) }
    #   end
    def contract(&)
      return @contract if defined?(@contract)

      @contract = Class.new(Kintide::Contract, &)
    end
  end

  # Contract is injectable for testing
  def initialize(contract: self.class.contract.new, **)
    @contract = contract
    super(**)
  end

  module Types
    include Kintide::Types
  end

private

  attr_reader :contract

  def Invalid(*) = Failure[:invalid, *] # rubocop:disable Naming/MethodName

  # First step of most operations: validate and coerce input.
  # Returns Success(hash of coerced params) or Failure[:invalid, errors].
  def validate(**input)
    contract
      .call(input)
      .to_monad
      .fmap(&:to_h)
      .or { |result| Invalid(result.errors.to_h) }
  end

  # Failure reasons that are part of normal user flows. Subclasses extend
  # this list to keep their expected failures out of error reporting:
  #
  #   EXPECTED_FAILURES = [*EXPECTED_FAILURES, :invalid_credentials].freeze
  EXPECTED_FAILURES = %i[invalid].freeze

  # dry-operation invokes this hook whenever a step fails. Reporting here
  # means controllers and callers never need to log failures themselves.
  def on_failure(failure)
    reason, * = failure
    return if self.class::EXPECTED_FAILURES.include?(reason)

    Rails.error.report(
      RuntimeError.new("#{self.class.name} failed: #{failure.inspect}"),
    )
  end
end
