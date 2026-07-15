FactoryBot.define do
  factory :subscription do
    circle
    name { Faker::Name.name }
    sequence(:phone_number) { |n| "+1212555#{format('%04d', 100 + n)}" }

    trait :active do
      state { 'active' }
      accepted_at { Time.current }
    end

    trait :deactivated do
      active

      state { 'deactivated' }
      deactivated_at { Time.current }
    end
  end
end
