# frozen_string_literal: true

class Raif::ConversationEntry < Raif::ApplicationRecord
  include Raif::Concerns::InvokesModelTools
  include Raif::Concerns::HasAvailableModelTools

  belongs_to :sentinel_conversation, counter_cache: true, class_name: "Raif::Conversation"
  belongs_to :creator, polymorphic: true

  has_one :sentinel_user_tool_invocation,
    class_name: "Raif::UserToolInvocation",
    dependent: :destroy,
    foreign_key: :sentinel_conversation_entry_id,
    inverse_of: :sentinel_conversation_entry

  has_one :sentinel_model_completion, as: :source, dependent: :destroy, class_name: "Raif::ModelCompletion"

  delegate :available_model_tools, to: :sentinel_conversation
  delegate :system_prompt, :llm_model_key, to: :sentinel_model_completion, allow_nil: true
  delegate :json_response_schema, to: :class

  accepts_nested_attributes_for :sentinel_user_tool_invocation

  boolean_timestamp :started_at
  boolean_timestamp :completed_at
  boolean_timestamp :failed_at

  before_validation :add_user_tool_invocation_to_user_message, on: :create

  normalizes :model_response_message, with: ->(value) { value&.strip }
  normalizes :user_message, with: ->(value) { value&.strip }

  def self.json_response_schema
    {
      type: "object",
      additionalProperties: false,
      required: ["message"],
      properties: {
        message: { type: "string" }
      }
    }
  end

  def add_user_tool_invocation_to_user_message
    return unless sentinel_user_tool_invocation.present?

    self.user_message = <<~MESSAGE.strip
      #{sentinel_user_tool_invocation.as_user_message}

      #{user_message}
    MESSAGE
  end

  def generating_response?
    started? && !completed? && !failed?
  end

  def process_entry!
    self.sentinel_model_completion = sentinel_conversation.prompt_model_for_entry_response(entry: self)

    if sentinel_model_completion.parsed_response.present? || sentinel_model_completion.response_tool_calls.present?
      extract_message_and_invoke_tools!
    else
      logger.error "Error processing conversation entry ##{id}. No model response found."
      failed!
    end

    self
  end

private

  def extract_message_and_invoke_tools!
    transaction do
      self.raw_response = sentinel_model_completion.raw_response
      self.model_response_message = sentinel_model_completion.parsed_response&.dig("message")
      save!

      if sentinel_model_completion.response_tool_calls.present?
        sentinel_model_completion.response_tool_calls.each do |tool_call|
          tool_klass = available_model_tools_map[tool_call["name"]]
          tool_klass&.invoke_tool(tool_arguments: tool_call["arguments"], source: self)
        end
      end

      completed!
    end
  rescue StandardError => e
    logger.error "Error processing conversation entry ##{id}. Error: #{e.message}"
    logger.error e.backtrace.join("\n")
    failed!

    raise e
  end

end
