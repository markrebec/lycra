FactoryGirl.define do
  factory :person do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    age { (18..65).to_a.sample }
  end
end
