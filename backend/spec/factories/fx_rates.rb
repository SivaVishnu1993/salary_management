FactoryBot.define do
  factory :fx_rate do
    currency { "USD" }
    usd_per_unit { 1 }

    # Currency is the primary key: reuse an existing row instead of colliding.
    initialize_with { FxRate.find_or_initialize_by(currency:) }
  end
end
