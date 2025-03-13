# frozen_string_literal: true

require "sentinel/version"
require "sentinel/languages"
require "sentinel/engine"
require "sentinel/configuration"
require "sentinel/errors"
require "sentinel/llm"
require "sentinel/model_tool"
require "sentinel/utils"

require "faraday"
require "loofah"
require "pagy"
require "reverse_markdown"

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

  def self.register_llm(llm_config)
    llm = Raif::Llm.new(**llm_config)

    unless llm.valid?
      raise ArgumentError, "The LLM you tried to register is invalid: #{llm.errors.full_messages.join(", ")}"
    end

    @llm_registry ||= {}
    @llm_registry[llm.key] = llm_config
  end

  def self.llm(model_key)
    Raif::Llm.new(**llm_registry[model_key])
  end

  def self.available_llms
    llm_registry.values
  end

  def self.available_llm_keys
    llm_registry.keys
  end
end
