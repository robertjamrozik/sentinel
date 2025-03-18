# frozen_string_literal: true

class Raif::ModelCompletion < Raif::ApplicationRecord
  include Raif::Concerns::LlmResponseParsing

  belongs_to :source, polymorphic: true, optional: true

  validates :llm_model_key, presence: true, inclusion: { in: ->{ Raif.available_llm_keys.map(&:to_s) } }
  validates :model_api_name, presence: true
  validates :type, presence: true

  # Triggers the call to the LLM to get the response. Must be implemented by llm provider-specific subclasses.
  def prompt_model_for_response!
    raise NotImplementedError, "Raif::ModelCompletion subclasses must implement #prompt_model_for_response!"
  end

end
