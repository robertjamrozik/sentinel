# frozen_string_literal: true

module Raif
  module ModelCompletions
    class Test < Raif::ModelCompletion
      attr_accessor :chat_handler

      def prompt_model_for_response!
        self.raw_response = chat_handler.call(messages)
        self.completion_tokens = rand(100..2000)
        self.prompt_tokens = rand(100..2000)
        self.total_tokens = completion_tokens + prompt_tokens

        save!
      end

    end
  end
end
