# frozen_string_literal: true

require "sentinel/version"
require "sentinel/languages"
require "sentinel/engine"
require "sentinel/configuration"
require "sentinel/errors"
require "sentinel/utils"
require "sentinel/llm_registry"
require "sentinel/embedding_model_registry"
require "sentinel/json_schema_builder"

require "faraday"
require "json-schema"
require "loofah"
require "pagy"
require "reverse_markdown"
require "turbo-rails"

module Raif
  class << self
    attr_accessor :configuration

    attr_writer :logger
  end

  def self.config
    @configuration ||= Raif::Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.logger
    @logger ||= Rails.logger
  end
end
