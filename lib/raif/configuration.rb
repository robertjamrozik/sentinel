# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :authorize_controller_action,
      :authorize_admin_controller_action,
      :anthropic_api_key,
      :anthropic_bedrock_models_enabled,
      :anthropic_models_enabled,
      :aws_bedrock_region,
      :base_system_prompt,
      :conversation_entries_controller,
      :open_ai_api_key,
      :open_ai_models_enabled,
      :conversation_types,
      :conversations_controller,
      :current_user_method,
      :default_llm_model_key,
      :llm_api_requests_enabled,
      :model_superclass,
      :user_tool_types

    def initialize
      # Set default config
      @aws_bedrock_region = "us-east-1"
      @anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
      @anthropic_bedrock_models_enabled = true
      @anthropic_models_enabled = true
      @authorize_controller_action = ->{ false }
      @authorize_admin_controller_action = ->{ false }
      @base_system_prompt = "You are a friendly assistant."
      @conversation_entries_controller = "Raif::ConversationEntriesController"
      @conversation_types = ["Raif::Conversation"]
      @conversations_controller = "Raif::ConversationsController"
      @current_user_method = :current_user
      @default_llm_model_key = "open_ai_gpt_4o"
      @llm_api_requests_enabled = true
      @model_superclass = "ApplicationRecord"
      @open_ai_api_key = ENV["OPENAI_API_KEY"]
      @open_ai_models_enabled = true
      @user_tool_types = []
    end

    def validate!
      unless Raif.available_llm_keys.include?(default_llm_model_key.to_sym)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_llm_model_key was set to #{default_llm_model_key}, but must be one of: #{Raif.available_llm_keys.join(", ")}"
      end

      if authorize_controller_action.respond_to?(:call)
        authorize_controller_action.freeze
      else
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.authorize_controller_action must respond to :call and return a boolean"
      end

      if authorize_admin_controller_action.respond_to?(:call)
        authorize_admin_controller_action.freeze
      else
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.authorize_admin_controller_action must respond to :call and return a boolean"
      end

      if open_ai_models_enabled && open_ai_api_key.blank?
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.open_ai_api_key is required when Raif.config.open_ai_models_enabled is true. Set it via Raif.config.open_ai_api_key or ENV[\"OPENAI_API_KEY\"]" # rubocop:disable Layout/LineLength
      end

      if anthropic_models_enabled && anthropic_api_key.blank?
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.anthropic_api_key is required when Raif.config.anthropic_models_enabled is true. Set it via Raif.config.anthropic_api_key or ENV['ANTHROPIC_API_KEY']" # rubocop:disable Layout/LineLength
      end
    end

  end
end
