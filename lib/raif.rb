# frozen_string_literal: true

require "sentinel/version"
require "sentinel/root"
require "sentinel/engine"
require "sentinel/configuration"
require "sentinel/errors"
require "sentinel/llm_client"
require "sentinel/model_tool"

require "openai"

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

  def self.available_models
    LlmClient.available_models
  end
end
