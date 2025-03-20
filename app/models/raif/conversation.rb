# frozen_string_literal: true

class Raif::Conversation < Raif::ApplicationRecord
  include Raif::Concerns::HasLlm
  include Raif::Concerns::HasRequestedLanguage

  belongs_to :creator, polymorphic: true

  has_many :entries, class_name: "Raif::ConversationEntry", dependent: :destroy, foreign_key: :sentinel_conversation_id, inverse_of: :sentinel_conversation

  validates :type, inclusion: { in: ->{ Raif.config.conversation_types } }

  before_validation ->{ self.type ||= "Raif::Conversation" }, on: :create

  def available_model_tools
    []
  end

  def tool_usage_system_prompt
    return if available_model_tools.empty?

    <<~PROMPT

      # Available Tools
      You have access to the following tools:
      #{available_model_tools.map(&:description_for_llm).join("\n---\n")}
      # Tool Usage
      To utilize a tool, include a tool object in your JSON response with the name of the tool you want to use and the arguments for that tool. An example response that invokes a tool:
      {
        "message": "I suggest we add a new scenario.",
        "tool": {
          "name": "tool_name",
          "arguments": {"arg_name": "Example arg"}
        }
      }
    PROMPT
  end

  def system_prompt
    <<~PROMPT
      #{system_prompt_intro}

      # Your Responses
      Your responses should always be in JSON format with a "message" field containing your response to your collaborator. For example:
      {
        "message": "Your response message"
      }
      #{tool_usage_system_prompt}
      #{system_prompt_reminders}
      #{system_prompt_language_preference}
    PROMPT
  end

  def system_prompt_intro
    Raif.config.conversation_system_prompt_intro
  end

  def system_prompt_tools_reminder
    return if available_model_tools.empty?

    "- Use tools if you think they are useful for the conversation.\n"
  end

  def system_prompt_reminders
    <<~PROMPT.strip
      # Other rules/reminders
      #{system_prompt_tools_reminder}- **Always** respond with a single, valid JSON object containing at minimum a "message" field, and optionally a "tool" field.
    PROMPT
  end

  def available_user_tools
    []
  end

  # i18n-tasks-use t('sentinel.conversation.initial_chat_message')
  def initial_chat_message
    I18n.t("#{self.class.name.underscore.gsub("/", ".")}.initial_chat_message")
  end

  def prompt_model_for_entry_response(entry:)
    llm.chat(messages: llm_messages, source: entry, response_format: :json, system_prompt: system_prompt)
  end

  def llm_messages
    messages = []

    entries.each do |entry|
      messages << { "role" => "user", "content" => entry.user_message }
      messages << { "role" => "assistant", "content" => entry.model_response_message } if entry.completed?
    end

    messages
  end

end
