module FxRates
  # Loads the static FX table (config/fx_rates.yml) into fx_rates so SQL can
  # convert to USD. Idempotent: re-running upserts the same rows.
  class Sync < ApplicationService
    def initialize(config: Config.current)
      @config = config
    end

    def call
      rows = config.usd_per_unit.map { |currency, usd_per_unit| { currency:, usd_per_unit: } }
      FxRate.upsert_all(rows, unique_by: :currency)
      Result.success(rows.size)
    end

    private

    attr_reader :config
  end
end
