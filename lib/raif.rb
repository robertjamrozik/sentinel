# frozen_string_literal: true

require "sentinel/version"
require "sentinel/engine"
require "sentinel/configuration"

require "sentinel/llm_client"
require "sentinel/model_tool"

require "openai"

module Raif
  class << self
    attr_accessor :configuration
  end

  def self.config
    @configuration ||= Raif::Configuration.new
  end

  def self.configure
    yield(config)
  end
end
