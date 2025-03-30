# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_agent, class: "Raif::Agent" do
    task { "What is Jimmy Buffet's birthday?" }
    available_model_tools { ["Raif::ModelTools::WikipediaSearch", "Raif::ModelTools::FetchUrl"] }
    creator { FB.create(:sentinel_test_user) }
  end

  factory :sentinel_native_tool_calling_agent, parent: :sentinel_agent, class: "Raif::Agents::NativeToolCallingAgent" do
  end

  factory :sentinel_re_act_agent, parent: :sentinel_agent, class: "Raif::Agents::ReActAgent" do
  end
end
