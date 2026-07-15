FactoryBot.define do
  factory :share do
    post
    subscription { association :subscription, :active, circle: post.circle }

    trait :delivered do
      delivered_at { Time.current }
    end
  end
end
