# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :aws_bedrock_region,
      :default_llm_model_name,
      :llm_api_requests_enabled

    def initialize
      @aws_bedrock_region = "us-east-1"
      @default_llm_model_name = "open_ai_gpt_4o"
      @llm_api_requests_enabled = true
    end

    def validate!
      unless Raif::LlmClient.available_models.include?(default_llm_model_name)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_llm_model_name was set to #{default_llm_model_name}, but must be one of: #{Raif::LlmClient.available_models.join(", ")}"
      end
    end

  end
end
