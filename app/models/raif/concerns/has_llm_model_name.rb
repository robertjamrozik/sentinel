# frozen_string_literal: true

module Raif::Concerns::HasLlmModelName
  extend ActiveSupport::Concern

  included do
    validates :llm_model_name, presence: true, inclusion: { in: Raif.available_llm_keys.map(&:to_s) }

    before_validation ->{ self.llm_model_name ||= default_llm_model_name }
  end

  def default_llm_model_name
    Raif.config.default_llm_model_name
  end
end
