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

      # Tool Usage
      You may also optionally include a <tool> tag with a JSON object containing the name of the tool you want to use and the arguments for that tool. An example response that invokes a tool:
      <message>I suggest we add a new scenario.</message>
      <tool>{"tool": "add_scenarios", "arguments": [{"title": "A new scenario", "description": "A description of the new scenario."}]}</tool>

      An example response that invokes no tools:
      <message>Could you clarify what you mean by that?</message>

      # Available Tools
      You have access to the following tools:
      #{available_model_tools.map(&:description_for_llm).join("\n---\n")}

    PROMPT
  end

  def system_prompt
    <<~PROMPT
      You are a helpful assistant who is collaborating with a teammate.

      # Your Responses
      Your responses should always begin with a <message> tag with your response to your collaborator. For example:
      <message>Your response message</message>
      #{tool_usage_system_prompt}
      # Other rules/reminders
      - Only use tools if you think they are useful for the conversation.
      - **Never** include the likelihood text in the scenario title (ie. don't suggest things like "A new scenario - low likelihood").
      - **Never** respond with any text outside the <message> and <tool> tags.
      #{system_prompt_language_preference}
    PROMPT
  end

  def available_user_tools
    []
  end

  def initial_chat_message
    I18n.t("#{self.class.name.underscore.gsub("/", ".")}.initial_chat_message")
  end

  def prompt_model_for_entry_response(entry:)
    llm.chat(messages: llm_messages, source: entry, system_prompt: system_prompt)
  end

  def llm_messages
    messages = []

    entries.each do |entry|
      if entry.completed?
        messages << { "role" => "user", "content" => entry.full_user_message }
        messages << { "role" => "assistant", "content" => entry.model_response_message }
      else
        messages << { "role" => "user", "content" => entry.full_user_message }
      end
    end

    messages
  end

end
