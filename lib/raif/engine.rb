# frozen_string_literal: true

begin
  require "factory_bot_rails"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

module Raif
  class Engine < ::Rails::Engine
    isolate_namespace Raif

    # If the host app is using FactoryBot, add the factories to the host app so they can be used in host apptests
    if defined?(FactoryBotRails)
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories/shared", __FILE__)]
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    config.after_initialize do
      next unless Raif.config.open_ai_models_enabled

      require "openai"

      ::OpenAI.configure do |config|
        config.access_token = Raif.config.open_ai_api_key
      end

      Raif.default_llms[Raif::ModelCompletions::OpenAi].each do |llm_config|
        Raif.register_llm(model_completion_type: Raif::ModelCompletions::OpenAi, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.anthropic_models_enabled

      require "anthropic"

      ::Anthropic.setup do |config|
        config.api_key = Raif.config.anthropic_api_key
      end

      Raif.default_llms[Raif::ModelCompletions::Anthropic].each do |llm_config|
        Raif.register_llm(model_completion_type: Raif::ModelCompletions::Anthropic, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.anthropic_bedrock_models_enabled

      require "aws-sdk-bedrock"
      require "aws-sdk-bedrockruntime"

      Raif.default_llms[Raif::ModelCompletions::BedrockClaude].each do |llm_config|
        Raif.register_llm(model_completion_type: Raif::ModelCompletions::BedrockClaude, **llm_config)
      end
    end

    config.after_initialize do
      next unless Rails.env.test?

      Raif.config.conversation_types += ["Raif::TestConversation"]

      require "#{Raif::Engine.root}/spec/support/test_completion"
      Raif.register_llm(model_completion_type: Raif::ModelCompletions::Test, key: :sentinel_test_llm, api_name: "sentinel-test-llm")
    end

    config.after_initialize do
      Raif.config.validate!
    end

    initializer "sentinel.assets" do
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += [
          "sentinel.js",
          "sentinel.css",
          "sentinel_admin.css"
        ]
      end
    end

    initializer "sentinel.importmap", before: "importmap" do |app|
      if Rails.application.respond_to?(:importmap)
        app.config.importmap.paths << Raif::Engine.root.join("config/importmap.rb")
      end
    end

  end
end
