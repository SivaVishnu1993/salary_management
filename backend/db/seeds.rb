# Demo data: static FX rates, the HR Manager login, and 10,000 employees.
# Idempotent: every run replaces employees and salaries with the same dataset.
#
#   bin/rails db:seed                      # 10,000 employees
#   SEED_EMPLOYEES=500 bin/rails db:seed   # smaller dataset
if Rails.env.production? && ENV["ALLOW_DESTRUCTIVE_SEED"] != "1"
  abort "Refusing to seed production: it truncates employees and salaries. Set ALLOW_DESTRUCTIVE_SEED=1 to override."
end

FxRates::Sync.call
puts "FX rates: #{FxRate.count} currencies"

hr_email = ENV.fetch("SEED_ADMIN_EMAIL", "hr@acme.test")
hr_password = ENV.fetch("SEED_ADMIN_PASSWORD") do
  abort "SEED_ADMIN_PASSWORD is required in production" if Rails.env.production?
  "password123"
end
User.find_or_initialize_by(email: hr_email).update!(name: "Hannah Reyes", password: hr_password)
puts "HR login: #{hr_email}"

count = Integer(ENV.fetch("SEED_EMPLOYEES", Seeds::Generator::DEFAULT_COUNT))
stats = Seeds::Generator.call(count:)
puts "Employees: #{stats.employees}, salary records: #{stats.salaries} (#{stats.seconds}s)"
