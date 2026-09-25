# Runs validations on `record` and returns the messages for one attribute,
# keeping validation examples to a single readable line.
module ValidationHelpers
  def validation_errors(record, attribute)
    record.validate
    record.errors[attribute]
  end
end

RSpec.configure do |config|
  config.include ValidationHelpers, type: :model
end
