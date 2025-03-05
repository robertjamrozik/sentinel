# frozen_string_literal: true

module Raif
  module Rspec
    module LlmStubbing

      class TestLlm
        attr_accessor :chat_handler

        def chat(messages:, system_prompt: nil)
          {
            response: chat_handler.call(messages),
            prompt_tokens: rand(1..4),
            completion_tokens: rand(10..30)
          }
        end
      end

      def stub_sentinel_completion(completion_class, &block)
        test_llm = TestLlm.new
        test_llm.chat_handler = block

        allow_any_instance_of(completion_class).to receive(:llm){ test_llm }
      end

    end
  end
end
