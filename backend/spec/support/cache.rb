# The test cache is an in-process memory store; isolate examples from each other.
RSpec.configure do |config|
  config.before { Rails.cache.clear }
end
