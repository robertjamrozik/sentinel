# frozen_string_literal: true

module Raif
  module Rspec
    module LlmStubbing

      class TestLlm
        attr_accessor :chat_handler

        def chat(messages:, response_format: :text, system_prompt: nil)
          Raif::ModelResponse.new(
            raw_response: chat_handler.call(messages),
            prompt_tokens: rand(1..4),
            completion_tokens: rand(10..30),
            total_tokens: rand(14..34)
          )
        end
      end

      def stub_sentinel_completion(completion_class, &block)
        test_llm = TestLlm.new
        test_llm.chat_handler = block

        allow_any_instance_of(completion_class).to receive(:llm){ test_llm }
      end

      def stub_sentinel_conversation(conversation, &block)
        test_llm = TestLlm.new
        test_llm.chat_handler = block

        if conversation.is_a?(Raif::Conversation)
          allow(conversation).to receive(:llm){ test_llm }
        else
          allow_any_instance_of(conversation).to receive(:llm){ test_llm }
        end
      end

    end
  end
end
