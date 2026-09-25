# Small, hand-checkable payroll used by insight specs. Rates are round numbers
# so expected USD values can be computed in your head:
#
#   country dept         title                     local          USD
#   US      Engineering  Senior Software Engineer  100,000 USD    100,000
#   US      Engineering  Senior Software Engineer  200,000 USD    200,000
#   US      Sales        Account Executive          50,000 USD     50,000
#   IN      Engineering  Senior Software Engineer 1,000,000 INR    10,000
#   IN      Engineering  Senior Software Engineer 3,000,000 INR    30,000
#   GB      Sales        Account Executive          40,000 GBP     60,000
module PayFixtures
  def create_sample_payroll
    create(:fx_rate, currency: "USD", usd_per_unit: 1)
    create(:fx_rate, currency: "INR", usd_per_unit: BigDecimal("0.01"))
    create(:fx_rate, currency: "GBP", usd_per_unit: BigDecimal("1.5"))

    [
      [ "US", "Engineering", "Senior Software Engineer", 100_000 ],
      [ "US", "Engineering", "Senior Software Engineer", 200_000 ],
      [ "US", "Sales", "Account Executive", 50_000 ],
      [ "IN", "Engineering", "Senior Software Engineer", 1_000_000 ],
      [ "IN", "Engineering", "Senior Software Engineer", 3_000_000 ],
      [ "GB", "Sales", "Account Executive", 40_000 ]
    ].map do |country, department, job_title, amount|
      create(:employee, country:, department:, job_title:, current_salary_cents: amount * 100)
    end
  end

  def usd(amount) = amount * 100
end

RSpec.configure do |config|
  config.include PayFixtures
end
