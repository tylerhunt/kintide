FactoryBot.define do
  factory :subscription do
    invitation factory: %i[invitation accepted]
    circle { invitation.circle }
    name { invitation.name }
    phone_number { invitation.phone_number }
  end
end
