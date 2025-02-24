# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :default_llm_model_name,
      :llm_api_requests_enabled

    def initialize
      @default_llm_model_name = "open_ai_gpt_4o"
      @llm_api_requests_enabled = true
    end
  end
end
