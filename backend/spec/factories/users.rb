FactoryBot.define do
  factory :user do
    name { "Hannah Reyes" }
    sequence(:email) { |n| "hr#{n}@acme.test" }
    password { "correct-horse-battery" }
  end
end
