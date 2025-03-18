# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_task, class: "Raif::Task" do
    sequence(:prompt){|i| "prompt #{i} #{SecureRandom.hex(3)}" }
    llm_model_key { Raif.available_llm_keys.sample.to_s }

    trait :completed do
      sequence(:raw_response){|i| "response #{i} #{SecureRandom.hex(3)}" }
      created_at { 1.minute.ago }
      started_at { 1.minute.ago }
      completed_at { 30.seconds.ago }
    end

    trait :failed do
      created_at { 1.minute.ago }
      started_at { 1.minute.ago }
      failed_at { 30.seconds.ago }
    end
  end

  factory :sentinel_test_task, parent: :sentinel_task, class: "Raif::TestTask" do
    type { "Raif::TestTask" }
  end
end
