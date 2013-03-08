# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :new_group do
    title "MyString"
    uuid "MyString"
    user_uuid "MyString"
    description "MyString"
    location ""
    category ""
    groups_above ""
  end
end
