# frozen_string_literal: true

module Raif
  module Llms
    class Test < Raif::Llm
      attr_accessor :chat_handler, :response_tool_calls

      def perform_model_completion!(model_completion)
        model_completion.raw_response = chat_handler.call(model_completion.messages)
        model_completion.response_tool_calls = response_tool_calls
        model_completion.completion_tokens = rand(100..2000)
        model_completion.prompt_tokens = rand(100..2000)
        model_completion.total_tokens = model_completion.completion_tokens + model_completion.prompt_tokens
        model_completion.save!

        model_completion
      end

    end
  end
end
