# frozen_string_literal: true

module Raif
  module RspecHelpers

    def stub_sentinel_task(task_class, &block)
      test_llm = Raif.llm(:sentinel_test_llm)
      test_llm.chat_handler = block

      allow(Raif.config).to receive(:llm_api_requests_enabled){ true }
      allow_any_instance_of(task_class).to receive(:llm){ test_llm }
    end

    def stub_sentinel_conversation(conversation, response_tool_calls: nil, &block)
      test_llm = Raif.llm(:sentinel_test_llm)
      test_llm.chat_handler = block
      test_llm.response_tool_calls = response_tool_calls

      allow(Raif.config).to receive(:llm_api_requests_enabled){ true }

      if conversation.is_a?(Raif::Conversation)
        allow(conversation).to receive(:llm){ test_llm }
      else
        allow_any_instance_of(conversation).to receive(:llm){ test_llm }
      end
    end

    def stub_sentinel_agent(agent, &block)
      test_llm = Raif.llm(:sentinel_test_llm)
      test_llm.chat_handler = block

      allow(Raif.config).to receive(:llm_api_requests_enabled){ true }

      if agent.is_a?(Raif::Agent)
        allow(agent).to receive(:llm){ test_llm }
      else
        allow_any_instance_of(agent).to receive(:llm){ test_llm }
      end
    end

    def stub_sentinel_llm(llm, &block)
      llm.chat_handler = block
      allow(Raif.config).to receive(:llm_api_requests_enabled){ true }
      llm
    end

  end
end
