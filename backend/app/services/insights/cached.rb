module Insights
  # Decorator that caches an insight's result. The key embeds the payroll data
  # version and the FX table version, so any employee/salary write or rate change
  # makes old entries unreachable. The TTL is only a safety net.
  #
  #   Insights::Cached.new(Insights::ByCountry).call(department: "Sales")
  class Cached
    TTL = 12.hours
    # While one request recomputes an expired entry, others keep serving the old
    # value briefly instead of all hitting the database at once.
    RACE_CONDITION_TTL = 10.seconds

    def initialize(insight, cache: Rails.cache, fx_version: FxRates::Config.current.version)
      @insight = insight
      @cache = cache
      @fx_version = fx_version
    end

    def call(**params)
      cache.fetch(key_for(params), expires_in: TTL, race_condition_ttl: RACE_CONDITION_TTL) do
        insight.call(**params)
      end
    end

    def key_for(params)
      digest = Digest::SHA256.hexdigest(params.compact.sort.to_json)[0, 16]
      [ "insights", insight.name.demodulize.underscore, "d#{CacheVersion.current(cache:)}", "fx#{fx_version}", digest ].join("/")
    end

    private

    attr_reader :insight, :cache, :fx_version
  end
end
