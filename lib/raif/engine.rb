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
      ActiveSupport.on_load(:action_view) do
        include Raif::Shared::ConversationsHelper
      end
    end

    config.after_initialize do
      next unless Raif.config.open_ai_models_enabled

      Raif.default_llms[Raif::Llms::OpenAi].each do |llm_config|
        Raif.register_llm(Raif::Llms::OpenAi, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.anthropic_models_enabled

      Raif.default_llms[Raif::Llms::Anthropic].each do |llm_config|
        Raif.register_llm(Raif::Llms::Anthropic, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.anthropic_bedrock_models_enabled

      require "aws-sdk-bedrock"
      require "aws-sdk-bedrockruntime"

      Raif.default_llms[Raif::Llms::BedrockClaude].each do |llm_config|
        Raif.register_llm(Raif::Llms::BedrockClaude, **llm_config)
      end
    end

    config.after_initialize do
      next unless Rails.env.test?

      Raif.config.conversation_types += ["Raif::TestConversation"]

      require "#{Raif::Engine.root}/spec/support/test_llm"
      Raif.register_llm(Raif::Llms::Test, key: :sentinel_test_llm, api_name: "sentinel-test-llm")
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
