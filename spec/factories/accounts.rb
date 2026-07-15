FactoryBot.define do
  factory :account do
    name { Faker::Name.name }
    email_address { Faker::Internet.unique.email }
    password { Faker::Internet.password(min_length: 8) }

    # every account owns exactly one circle, mirroring Accounts::Create
    circle { association :circle, account: instance }
  end
end
