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
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories", __FILE__)]
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    initializer "sentinel.register_available_llms" do
      [
        {
          key: :open_ai_gpt_4o_mini,
          api_name: "gpt-4o-mini",
          api_adapter: Raif::ApiAdapters::OpenAi
        },
        {
          key: :open_ai_gpt_4o,
          api_name: "gpt-4o",
          api_adapter: Raif::ApiAdapters::OpenAi
        },
        {
          key: :open_ai_gpt_3_5_turbo,
          api_name: "gpt-3.5-turbo",
          api_adapter: Raif::ApiAdapters::OpenAi
        },
        {
          key: :bedrock_claude_3_5_sonnet,
          api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          api_adapter: Raif::ApiAdapters::Bedrock
        }
      ].each do |llm_config|
        Raif.register_llm(llm_config)
      end
    end

    initializer "sentinel.validate_config" do
      Raif.config.validate!
    end

    initializer "sentinel.assets" do |app|
      app.config.assets.precompile += [
        "sentinel.js",
        "sentinel.css"
      ]
    end

    initializer "sentinel.importmap", before: "importmap" do |app|
      if Rails.application.respond_to?(:importmap)
        app.config.importmap.paths << Raif::Engine.root.join("config/importmap.rb")
      end
    end

  end
end
