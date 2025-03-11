# frozen_string_literal: true

module Raif
  class Llm
    include ActiveModel::Model

    attr_accessor :key, :api_name, :api_adapter

    validates :key, presence: true
    validates :api_name, presence: true
    validates :api_adapter, presence: true

    VALID_RESPONSE_FORMATS = [:text, :json, :html].freeze

    def initialize(key:, api_name:, api_adapter:)
      @key = key
      @api_name = api_name
      @api_adapter = api_adapter.new(model_api_name: api_name)
    end

    def name
      I18n.t("sentinel.model_names.#{key}")
    end

    def chat(messages:, source:, response_format: :text, system_prompt: nil)
      unless response_format.is_a?(Symbol)
        raise ArgumentError,
          "Raif::Llm#chat - Invalid response format: #{response_format}. Must be a symbol (you passed #{response_format.class}) and be one of: #{VALID_RESPONSE_FORMATS.join(", ")}" # rubocop:disable Layout/LineLength
      end

      unless VALID_RESPONSE_FORMATS.include?(response_format)
        raise ArgumentError, "Raif::Llm#chat - Invalid response format: #{response_format}. Must be one of: #{VALID_RESPONSE_FORMATS.join(", ")}"
      end

      unless Raif.config.llm_api_requests_enabled
        Raif.logger.warn("LLM API requests are disabled. Skipping request to #{adapter.model_api_name}.")
        return
      end

      model_response = @api_adapter.chat(messages: messages, system_prompt: system_prompt)
      model_response.llm_model_key = key.to_s
      model_response.response_format = response_format
      model_response.source = source
      model_response.save!
      model_response
    end

    def self.valid_response_formats
      VALID_RESPONSE_FORMATS
    end
  end
end
