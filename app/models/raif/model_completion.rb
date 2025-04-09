# frozen_string_literal: true

class Raif::ModelCompletion < Raif::ApplicationRecord
  include Raif::Concerns::LlmResponseParsing
  include Raif::Concerns::HasAvailableModelTools

  belongs_to :source, polymorphic: true, optional: true

  validates :llm_model_key, presence: true, inclusion: { in: ->{ Raif.available_llm_keys.map(&:to_s) } }
  validates :model_api_name, presence: true

  delegate :json_response_schema, to: :source, allow_nil: true

  before_save :set_total_tokens

  after_initialize -> { self.messages ||= [] }
  after_initialize -> { self.available_model_tools ||= [] }

  def json_response_schema
    source.json_response_schema if source&.respond_to?(:json_response_schema)
  end

  def prompt_token_cost
    return if prompt_tokens.blank? || llm_config[:input_token_cost].blank?

    llm_config[:input_token_cost] * prompt_tokens
  end

  def output_token_cost
    return if completion_tokens.blank? || llm_config[:output_token_cost].blank?

    llm_config[:output_token_cost] * completion_tokens
  end

  def total_cost
    return if prompt_token_cost.blank? && output_token_cost.blank?

    prompt_token_cost + output_token_cost
  end

protected

  def set_total_tokens
    self.total_tokens ||= completion_tokens.present? && prompt_tokens.present? ? completion_tokens + prompt_tokens : nil
  end

private

  def llm_config
    @llm_config ||= Raif.llm_config(llm_model_key.to_sym)
  end
end
