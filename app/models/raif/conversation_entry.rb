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

  has_one :model_response, as: :source, dependent: :destroy

  delegate :available_model_tools, to: :sentinel_conversation

  accepts_nested_attributes_for :sentinel_user_tool_invocation

  boolean_timestamp :started_at
  boolean_timestamp :completed_at
  boolean_timestamp :failed_at

  def full_user_message
    if sentinel_user_tool_invocation.present?
      <<~MESSAGE
        #{sentinel_user_tool_invocation.as_user_message}

        #{user_message}
      MESSAGE
    else
      user_message
    end.strip
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
      failed!
    end

    self
  end

private

  # We expect the the model to respond with something like (tool being optional):
  # <message>The message to display to the user</message>
  # <tool>{ "name": "tool_name", "arguments": { "argument_name": "argument_value" } }</tool>
  def extract_message_and_invoke_tools!
    transaction do
      self.model_response_message = model_raw_response.match(%r{<message>(.*?)</message>}m)[1].strip
      save!

      tool_json = model_raw_response.match(%r{<tool>(.*?)</tool>}m)[1].strip
      tool_call = JSON.parse(tool_json) if tool_json.present?
      tool_klass = available_model_tools_map[tool_call["name"]]
      next unless tool_klass

      tool_klass.invoke_tool(tool_arguments: tool_call["arguments"], source: self)

      completed!
    end
  end

end
