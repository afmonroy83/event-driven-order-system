FactoryBot.define do
  factory :customer do
    name { Faker::Name.name }
    address { Faker::Address.full_address }
    orders_count { Faker::Number.between(from: 0, to: 10) }
  end
end