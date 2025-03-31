# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_conversation_entry, class: "Raif::ConversationEntry" do
    sequence(:user_message){|i| "User message #{i} #{SecureRandom.hex(4)}" }
    creator { sentinel_conversation.creator }

    trait :completed do
      sequence(:model_response_message){|i| "Model response #{i} #{SecureRandom.hex(4)}" }
      started_at { Time.current }
      completed_at { Time.current }
    end

    trait :with_tool_invocation do
      after(:create) do |entry|
        create(:sentinel_model_tool_invocation, source: entry)
      end
    end
  end
end
