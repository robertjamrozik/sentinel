# frozen_string_literal: true

module Raif
  class Llm
    include ActiveModel::Model

    attr_accessor :key,
      :api_name,
      :default_temperature,
      :default_max_completion_tokens,
      :model_completion_type

    validates :key, presence: true
    validates :api_name, presence: true
    validates :model_completion_type, presence: true

    VALID_RESPONSE_FORMATS = [:text, :json, :html].freeze

    def initialize(key:, api_name:, model_completion_type:, temperature: nil, max_completion_tokens: nil)
      @key = key
      @api_name = api_name
      @model_completion_type = model_completion_type
      @default_temperature = temperature
      @default_max_completion_tokens = max_completion_tokens
    end

    def name
      I18n.t("sentinel.model_names.#{key}")
    end

    def chat(message: nil, messages: nil, response_format: :text, source: nil, system_prompt: nil, temperature: nil, max_completion_tokens: nil)
      unless response_format.is_a?(Symbol)
        raise ArgumentError,
          "Raif::Llm#chat - Invalid response format: #{response_format}. Must be a symbol (you passed #{response_format.class}) and be one of: #{VALID_RESPONSE_FORMATS.join(", ")}" # rubocop:disable Layout/LineLength
      end

      unless VALID_RESPONSE_FORMATS.include?(response_format)
        raise ArgumentError, "Raif::Llm#chat - Invalid response format: #{response_format}. Must be one of: #{VALID_RESPONSE_FORMATS.join(", ")}"
      end

      unless message.present? || messages.present?
        raise ArgumentError, "Raif::Llm#chat - You must provide either a message: or messages: argument"
      end

      if message.present? && messages.present?
        raise ArgumentError, "Raif::Llm#chat - You must provide either a message: or messages: argument, not both"
      end

      unless Raif.config.llm_api_requests_enabled
        Raif.logger.warn("LLM API requests are disabled. Skipping request to #{api_name}.")
        return
      end

      messages = [{ role: "user", content: message }] if message.present?

      temperature ||= default_temperature
      max_completion_tokens ||= default_max_completion_tokens

      model_completion = model_completion_type.new(
        messages: messages,
        system_prompt: system_prompt,
        response_format: response_format,
        source: source,
        llm_model_key: key.to_s,
        model_api_name: api_name,
        temperature: temperature,
        max_completion_tokens: max_completion_tokens
      )

      before_model_completion_prompt_hook(model_completion)
      model_completion.prompt_model_for_response!
      model_completion
    end

    def before_model_completion_prompt_hook(model_completion)
      # no-op
    end

    def self.valid_response_formats
      VALID_RESPONSE_FORMATS
    end

  end
end
