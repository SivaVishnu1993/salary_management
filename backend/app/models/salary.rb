# One effective-dated salary record. Rows are append-only: a pay change inserts a
# new row (via Salaries::Change), so history doubles as the audit trail.
class Salary < ApplicationRecord
  include Monetizable
  include InvalidatesInsightsCache

  NOTE_MAX_LENGTH = 500
  # Sanity ceiling in USD terms: catches typos such as extra zeros, which would
  # otherwise flow straight into payroll totals.
  MAX_PLAUSIBLE_USD_CENTS = 10_000_000_00

  belongs_to :employee, inverse_of: :salaries

  monetize :amount, currency_column: :currency
  delegate :country, to: :employee, prefix: true, allow_nil: true

  normalizes :currency, with: ->(code) { code.strip.upcase }

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, currency_matches_country: { country: :employee_country }
  validates :effective_date, presence: true, not_in_future: true, uniqueness: { scope: :employee_id }
  validates :note, length: { maximum: NOTE_MAX_LENGTH }
  validate :amount_plausible

  scope :effective_on_or_before, ->(date) { where(effective_date: ..date) }
  scope :chronological, -> { order(:effective_date, :id) }
  scope :latest_first, -> { order(effective_date: :desc, id: :desc) }

  # Persisted rows are immutable; corrections are made by recording a new salary.
  def readonly? = persisted? || super

  private

  def amount_plausible
    rate = FxRates::Config.current.usd_per_unit[currency]
    return if rate.nil? || !amount_cents.is_a?(Integer) || !amount_cents.positive?
    return if amount.to_usd(rate).cents <= MAX_PLAUSIBLE_USD_CENTS

    errors.add(:amount_cents, :implausibly_large, limit: "$#{(MAX_PLAUSIBLE_USD_CENTS / 100).to_fs(:delimited)}")
  end
end
