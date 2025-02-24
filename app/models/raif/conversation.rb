# frozen_string_literal: true

class Raif::Conversation < Raif::ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_many :entries, class_name: "Raif::ConversationEntry", dependent: :destroy, foreign_key: :sentinel_conversation_id, inverse_of: :sentinel_conversation
  has_many :sentinel_completions, through: :entries

  def available_model_tools
    []
  end

  def system_prompt_addition
    <<~PROMPT
      Your response should be a JSON object with the following format:
      { "message": "Your message to be displayed to the user" }
    PROMPT
  end

  def available_user_tools
    []
  end

  def initial_chat_message
    I18n.t("#{self.class.name.underscore.gsub("/", ".")}.initial_chat_message")
  end

  def llm_messages
    messages = []

    entries.preload(:sentinel_completion).each do |entry|
      if entry.completed?
        messages << { "role" => "user", "content" => entry.sentinel_completion_prompt }
        messages << { "role" => "assistant", "content" => entry.sentinel_completion_response }
      else
        messages << { "role" => "user", "content" => entry.full_user_message }
      end
    end

    messages
  end

end
