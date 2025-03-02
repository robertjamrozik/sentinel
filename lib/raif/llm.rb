# frozen_string_literal: true

module Raif
  class Llm
    include ActiveModel::Model

    attr_accessor :key, :api_name, :api_adapter

    validates :key, presence: true
    validates :api_name, presence: true
    validates :api_adapter, presence: true

    def initialize(key:, api_name:, api_adapter:)
      @key = key
      @api_name = api_name
      @api_adapter = api_adapter.new(model_api_name: api_name)
    end

    def name
      I18n.t("sentinel.model_names.#{key}")
    end

    def chat(messages:, system_prompt: nil)
      unless Raif.config.llm_api_requests_enabled
        Raif.logger.warn("LLM API requests are disabled. Skipping request to #{adapter.model_api_name}.")
        return
      end

      @api_adapter.chat(messages: messages, system_prompt: system_prompt)
    end
  end
end
