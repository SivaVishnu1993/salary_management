FactoryBot.define do
  factory :employee do
    first_name { "Ada" }
    sequence(:last_name) { |n| "Lovelace#{n}" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    department { "Engineering" }
    job_title { "Senior Software Engineer" }
    country { "US" }
    hire_date { Date.new(2021, 3, 15) }
    current_salary_cents { 120_000_00 }
    current_salary_currency { Country.currency_for(country) }
  end
end
