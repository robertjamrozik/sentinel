# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_completion, class: "Raif::Completion" do
    sequence(:prompt){|i| "prompt #{i} #{SecureRandom.hex(3)}" }
    llm_model_key { Raif.available_llm_keys.sample.to_s }

    trait :completed do
      sequence(:response){|i| "response #{i} #{SecureRandom.hex(3)}" }
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

  factory :sentinel_test_completion, parent: :sentinel_completion, class: "Raif::TestCompletion" do
    type { "Raif::TestCompletion" }
  end
end
