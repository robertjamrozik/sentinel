# frozen_string_literal: true

module Raif
  module ApiAdapters
    class Anthropic < Base
      attr_accessor :temperature, :max_tokens

      def initialize(**args)
        args[:temperature] ||= 0.7
        args[:max_tokens] ||= 4096
        super(**args)
      end

      def chat(messages:, system_prompt: nil)
        params = {
          model: model_api_name,
          messages: messages,
          temperature: temperature,
          max_tokens: max_tokens
        }

        params[:system] = system_prompt if system_prompt
        resp = ::Anthropic.messages.create(**params)

        Raif::ModelResponse.new(
          messages: messages,
          system_prompt: system_prompt,
          raw_response: resp.body&.dig(:content)&.first&.dig(:text),
          completion_tokens: resp.body&.dig(:usage, :output_tokens),
          prompt_tokens: resp.body&.dig(:usage, :input_tokens),
          total_tokens: (resp.body&.dig(:usage, :output_tokens) || 0) + (resp.body&.dig(:usage, :input_tokens) || 0)
        )
      end
    end
  end
end
