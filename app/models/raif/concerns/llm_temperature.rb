# frozen_string_literal: true

module Raif::Concerns::LlmTemperature
  extend ActiveSupport::Concern

  included do
    class_attribute :temperature, instance_writer: false
  end

  class_methods do
    def llm_temperature(temperature)
      raise ArgumentError, "temperature must be a number between 0 and 1" unless temperature.is_a?(Numeric) && temperature.between?(0, 1)

      self.temperature = temperature
    end
  end
end
