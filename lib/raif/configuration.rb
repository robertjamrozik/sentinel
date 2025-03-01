# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :authorize_controller_action,
      :aws_bedrock_region,
      :base_system_prompt,
      :conversation_entries_controller,
      :conversation_types,
      :conversations_controller,
      :current_user_method,
      :default_llm_model_name,
      :llm_api_requests_enabled,
      :user_tool_types

    def initialize
      @aws_bedrock_region = "us-east-1"
      @authorize_controller_action = ->{ false }
      @base_system_prompt = "You are a friendly assistant."
      @conversation_entries_controller = "Raif::ConversationEntriesController"
      @conversation_types = ["Raif::Conversation"]
      @conversations_controller = "Raif::ConversationsController"
      @current_user_method = :current_user
      @default_llm_model_name = "open_ai_gpt_4o"
      @llm_api_requests_enabled = true
      @user_tool_types = []
    end

    def validate!
      unless Raif::LlmClient.available_models.include?(default_llm_model_name)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_llm_model_name was set to #{default_llm_model_name}, but must be one of: #{Raif::LlmClient.available_models.join(", ")}" # rubocop:disable Layout/LineLength
      end

      if @authorize_controller_action.respond_to?(:call)
        @authorize_controller_action.freeze
      else
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.authorize_controller_action must respond to :call and return a boolean"
      end
    end

  end
end
