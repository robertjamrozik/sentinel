# frozen_string_literal: true

class Raif::ConversationEntry < Raif::ApplicationRecord
  include Raif::Concerns::InvokesModelTools

  belongs_to :sentinel_conversation, counter_cache: true, class_name: "Raif::Conversation"
  belongs_to :creator, polymorphic: true

  has_one :sentinel_user_tool_invocation,
    class_name: "Raif::UserToolInvocation",
    dependent: :destroy,
    foreign_key: :sentinel_conversation_entry_id,
    inverse_of: :sentinel_conversation_entry

  has_one :sentinel_model_response, as: :source, dependent: :destroy, class_name: "Raif::ModelResponse"

  delegate :available_model_tools, to: :sentinel_conversation
  delegate :system_prompt, :llm_model_key, to: :sentinel_model_response, allow_nil: true

  accepts_nested_attributes_for :sentinel_user_tool_invocation

  boolean_timestamp :started_at
  boolean_timestamp :completed_at
  boolean_timestamp :failed_at

  before_validation :add_user_tool_invocation_to_user_message, on: :create

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
    model_response = sentinel_conversation.prompt_model_for_entry_response(entry: self)
    self.model_raw_response = model_response.raw_response

    if model_raw_response.present?
      extract_message_and_invoke_tools!
    else
      logger.error "Error processing conversation entry ##{id}. No model response found."
      failed!
    end

    self
  end

private

  # We expect the the model to respond with JSON like:
  # {
  #   "message": "The message to display to the user",
  #   "tool": {
  #     "name": "tool_name",
  #     "arguments": { "argument_name": "argument_value" }
  #   }
  # }
  def extract_message_and_invoke_tools!
    transaction do
      parsed_response = JSON.parse(model_raw_response)

      if parsed_response["message"].blank?
        logger.error "Error extracting message from conversation entry ##{id}. No model response message found."
        failed!
        return
      end

      self.model_response_message = parsed_response["message"].strip
      save!

      if parsed_response["tool"].present?
        tool_call = parsed_response["tool"]
        tool_klass = available_model_tools_map[tool_call["name"]]
        tool_klass&.invoke_tool(tool_arguments: tool_call["arguments"], source: self)
      end

      completed!
    rescue JSON::ParserError => e
      logger.error "Error parsing JSON response for conversation entry ##{id}. Error: #{e.message}"
      logger.error e.backtrace.join("\n")
      failed!
      return
    end
  end

end
