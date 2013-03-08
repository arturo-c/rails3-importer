# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :member do
    uuid "MyString"
    group_uuid "MyString"
    role_uuid "MyString"
    role_name "MyString"
    local false
  end
end
