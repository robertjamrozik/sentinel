# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_agent_invocation, class: "Raif::AgentInvocation" do
    task { "What is the capital of France?" }
    llm_model_key { Raif.available_llm_keys.sample.to_s }
    available_model_tools { ["Raif::TestModelTool"] }
  end
end
