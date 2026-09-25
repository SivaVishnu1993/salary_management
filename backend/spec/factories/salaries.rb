FactoryBot.define do
  factory :salary do
    employee
    amount_cents { 120_000_00 }
    currency { Country.currency_for(employee.country) }
    effective_date { employee.hire_date }
  end
end
