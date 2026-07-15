FactoryBot.define do
  factory :account do
    name { 'Tyler' }
    email_address { 'tyler@example.com' }
    password { 'sekret-password' }

    # every account owns exactly one circle, mirroring Accounts::Create
    after(:create) do |account|
      account.create_circle!(name: "#{account.name}'s Circle")
    end
  end
end
