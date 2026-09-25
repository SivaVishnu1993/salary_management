module Insights
  # A token that changes whenever payroll data changes. Cached insights embed it
  # in their keys, so bumping it invalidates every entry at once without scanning
  # or deleting keys; stale entries simply expire.
  module CacheVersion
    KEY = "insights/payroll_data_version".freeze

    def self.current(cache: Rails.cache) = cache.fetch(KEY) { new_token }

    def self.bump!(cache: Rails.cache) = cache.write(KEY, new_token)

    def self.new_token = SecureRandom.hex(8)
    private_class_method :new_token
  end
end
