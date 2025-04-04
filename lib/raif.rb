# frozen_string_literal: true

require "sentinel/version"
require "sentinel/languages"
require "sentinel/engine"
require "sentinel/configuration"
require "sentinel/errors"
require "sentinel/utils"
require "sentinel/default_llms"

require "faraday"
require "json-schema"
require "loofah"
require "pagy"
require "reverse_markdown"
require "turbo-rails"

module Raif
  class << self
    attr_accessor :configuration
    attr_accessor :llm_registry

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

  def self.register_llm(llm_class, llm_config)
    llm = llm_class.new(**llm_config)

    unless llm.valid?
      raise ArgumentError, "The LLM you tried to register is invalid: #{llm.errors.full_messages.join(", ")}"
    end

    @llm_registry ||= {}
    @llm_registry[llm.key] = llm_config.merge(llm_class: llm_class)
  end

  def self.llm(model_key)
    llm_config = llm_registry[model_key]

    if llm_config.nil?
      raise ArgumentError, "No LLM found for model key: #{model_key}. Available models: #{available_llm_keys.join(", ")}"
    end

    llm_class = llm_config[:llm_class]
    llm_class.new(**llm_config.except(:llm_class))
  end

  def self.available_llms
    llm_registry.values
  end

  def self.available_llm_keys
    llm_registry.keys
  end
end
