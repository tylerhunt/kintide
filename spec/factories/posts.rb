FactoryBot.define do
  factory :post do
    circle
    body { Faker::Lorem.paragraph }
  end
end
