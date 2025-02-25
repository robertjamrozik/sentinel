# frozen_string_literal: true

begin
  require "factory_bot_rails"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

module Raif
  class Engine < ::Rails::Engine
    isolate_namespace Raif

    if defined?(FactoryBotRails)
      puts "Adding factory paths"
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories", __FILE__)]
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    initializer "sentinel.validate_config" do
      Raif.config.validate!
    end

  end
end
