# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_test_user, class: "Raif::TestUser" do
    sequence(:email){|i| "user-#{SecureRandom.hex(3)}-#{i}@example.com" }
  end
end
