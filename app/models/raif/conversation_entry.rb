# frozen_string_literal: true

class Raif::ConversationEntry < Raif::ApplicationRecord
  belongs_to :sentinel_conversation, counter_cache: true, class_name: "Raif::Conversation"
  belongs_to :creator, polymorphic: true

  has_one :sentinel_user_tool_invocation,
    class_name: "Raif::UserToolInvocation",
    dependent: :destroy,
    foreign_key: :sentinel_conversation_entry_id,
    inverse_of: :sentinel_conversation_entry

  has_one :sentinel_completion,
    class_name: "Raif::Completion",
    dependent: :destroy,
    foreign_key: :sentinel_conversation_entry_id,
    inverse_of: :sentinel_conversation_entry

  delegate :prompt, :response, to: :sentinel_completion, prefix: true

  accepts_nested_attributes_for :sentinel_user_tool_invocation

  boolean_timestamp :started_at
  boolean_timestamp :completed_at
  boolean_timestamp :failed_at

  before_save :extract_model_response_message

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

  def extract_model_response_message
    return unless model_raw_response.present?

    self.model_response_message = model_raw_response.match(%r{<message>(.*?)</message>}m)[1].strip
  end

  def generating_response?
    started? && !completed? && !failed?
  end

  def model_tool_invocations
    sentinel_completion&.model_tool_invocations || []
  end

end
