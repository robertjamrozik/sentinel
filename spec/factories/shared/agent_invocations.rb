# frozen_string_literal: true

FactoryBot.define do
  factory :sentinel_agent_invocation, class: "Raif::AgentInvocation" do
    task { "What is the capital of France?" }
    llm_model_key { Raif.available_llm_keys.sample.to_s }
    system_prompt { Raif::Agent.new(task: "test task", tools: [], creator: nil).system_prompt }
  end
end
