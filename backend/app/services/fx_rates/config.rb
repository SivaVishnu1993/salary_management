module FxRates
  # The static, versioned FX table from config/fx_rates.yml.
  Config = Data.define(:version, :as_of, :usd_per_unit) do
    def self.load(path = Rails.root.join("config/fx_rates.yml"))
      raw = YAML.load_file(path, permitted_classes: [ Date ])
      new(version: raw.fetch("version", 1), as_of: raw.fetch("as_of"),
          usd_per_unit: raw.fetch("usd_per_unit").transform_values { |rate| BigDecimal(rate.to_s) }.freeze)
    end

    def self.current = @current ||= load
  end
end
