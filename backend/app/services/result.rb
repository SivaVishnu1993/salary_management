# Outcome of a service call. Expected failures (bad credentials, invalid input)
# are returned, not raised, so callers branch on them explicitly.
class Result
  attr_reader :value, :error

  def self.success(value = nil) = new(value:)

  def self.failure(error) = new(error:)

  def initialize(value: nil, error: nil)
    @value = value
    @error = error
    freeze
  end

  def success? = error.nil?

  def failure? = !success?
end
