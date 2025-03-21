# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_conversation, class: "Raif::Conversation" do
    trait :with_entries do
      transient do
        entries_count { 3 }
      end

      after(:create) do |conversation, evaluator|
        create_list(:sentinel_conversation_entry, evaluator.entries_count, :completed, sentinel_conversation: conversation)
      end
    end
  end

  factory :sentinel_test_conversation, class: "Raif::TestConversation", parent: :sentinel_conversation do
  end
end
