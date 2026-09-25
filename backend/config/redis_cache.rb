# Shared options for the Redis-backed Rails.cache (development + production).
#
# Redis is an optimisation, not a dependency: tight timeouts plus an error
# handler mean a Redis outage degrades to cache misses (queries hit Postgres)
# instead of failing requests.
module RedisCache
  NAMESPACE = "salary_management".freeze
  DEFAULT_URL = "redis://localhost:6379/0".freeze
  DEFAULT_TTL = 12 * 60 * 60 # seconds; safety net on top of version-based invalidation

  def self.options
    {
      url: ENV.fetch("REDIS_URL", DEFAULT_URL),
      namespace: NAMESPACE,
      expires_in: DEFAULT_TTL,
      connect_timeout: 1,
      read_timeout: 0.5,
      write_timeout: 0.5,
      reconnect_attempts: 1,
      error_handler: method(:log_error)
    }
  end

  def self.log_error(method:, returning:, exception:)
    Rails.logger.warn("[cache] Redis #{method} failed (#{exception.class}: #{exception.message}); returning #{returning.inspect}")
  end
end
