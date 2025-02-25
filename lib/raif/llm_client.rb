# frozen_string_literal: true

require_relative "adapters/base"
require_relative "adapters/open_ai"
require_relative "adapters/bedrock"

module Raif
  class LlmClient
    attr_accessor :adapter

    def initialize(model_name:)
      model_config = Raif::LlmClient.config_for_model(model_name)
      raise ArgumentError, "Invalid model name - #{model_name}" unless model_config.present?

      @adapter = model_config[:adapter].new(model_api_name: model_config[:model_api_name])
    end

    def chat(messages:, system_prompt: nil)
      unless Raif.config.llm_api_requests_enabled
        Raif.logger.warn("LLM API requests are disabled. Skipping request to #{adapter.model_api_name}.")
        return
      end

      adapter.chat(messages: messages, system_prompt: system_prompt)
    end

    def self.available_models
      @available_models ||= MODEL_CONFIG.keys.map(&:to_s)
    end

    def self.config_for_model(model_name)
      MODEL_CONFIG[model_name.to_sym]
    end

    MODEL_CONFIG = {
      open_ai_gpt_4o_mini: {
        model_api_name: "gpt-4o-mini",
        adapter: Raif::Adapters::OpenAi
      }.freeze,
      open_ai_gpt_4o: {
        model_api_name: "gpt-4o",
        adapter: Raif::Adapters::OpenAi
      }.freeze,
      open_ai_gpt_3_5_turbo: {
        model_api_name: "gpt-3.5-turbo",
        adapter: Raif::Adapters::OpenAi
      }.freeze,
      bedrock_claude_3_5_sonnet: {
        model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
        adapter: Raif::Adapters::Bedrock
      }
    }.freeze
  end
end
