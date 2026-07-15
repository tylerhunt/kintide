FactoryBot.define do
  factory :circle do
    account { association :account, circle: instance }
    name { "The #{Faker::Name.last_name}s" }
  end
end
