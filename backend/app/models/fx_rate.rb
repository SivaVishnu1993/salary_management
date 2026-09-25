# Static USD conversion rate for one currency (loaded from config/fx_rates.yml).
class FxRate < ApplicationRecord
  self.primary_key = :currency

  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :usd_per_unit, numericality: { greater_than: 0 }
end
