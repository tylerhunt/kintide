FactoryBot.define do
  factory :invitation do
    circle
    name { Faker::Name.name }
    sequence(:phone_number) { |n| "+1212555#{format('%04d', 100 + n)}" }

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
