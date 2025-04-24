# frozen_string_literal: true

class Raif::ModelToolInvocation < Raif::ApplicationRecord
  belongs_to :source, polymorphic: true

  after_initialize -> { self.tool_arguments ||= {} }
  after_initialize -> { self.result ||= {} }

  validates :tool_type, presence: true
  validate :ensure_valid_tool_argument_schema, if: -> { tool_type.present? && tool_arguments_schema.present? }

  delegate :tool_arguments_schema,
    :renderable?,
    :tool_name,
    :triggers_observation_to_model?,
    to: :tool

  boolean_timestamp :completed_at
  boolean_timestamp :failed_at

  def tool
    @tool ||= tool_type.constantize
  end

  def as_llm_message
    "Invoking tool: #{tool_name} with arguments: #{tool_arguments.to_json}"
  end

  def result_llm_message
    return unless tool.respond_to?(:observation_for_invocation)

    tool.observation_for_invocation(self)
  end

  def to_partial_path
    "sentinel/model_tool_invocations/#{tool.invocation_partial_name}"
  end

  def ensure_valid_tool_argument_schema
    unless JSON::Validator.validate(tool_arguments_schema, tool_arguments)
      errors.add(:tool_arguments, "does not match schema")
    end
  end

end
