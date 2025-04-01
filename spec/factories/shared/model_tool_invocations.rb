# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_model_tool_invocation, class: "Raif::ModelToolInvocation" do
    source { create(:sentinel_conversation_entry) }
    tool_type { "Raif::TestModelTool" }
    tool_arguments { { "items": [{ "title": "foo", "description": "bar" }] } }

    trait :with_result do
      result { { "status": "success" } }
    end
  end
end
