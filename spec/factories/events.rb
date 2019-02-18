FactoryBot.define do
  factory :event do
    start_date { Faker::Date.forward(666) }
    duration { rand(6..120) * 5 }
    title { Faker::Book.title }
    description { Faker::Lorem.paragraph(10) }
    price { rand(1..1000) }
    location { Faker::Address.full_address }
    admin { FactoryBot.create(:user) }
  end
end
