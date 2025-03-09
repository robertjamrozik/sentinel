# frozen_string_literal: true

module Raif::Completions
  class ConversationEntry < Raif::Completion
    llm_response_format :json
    llm_completion_args :sentinel_conversation_entry

    delegate :sentinel_conversation, to: :sentinel_conversation_entry

    def build_system_prompt
      <<~PROMPT
        #{super}

        #{sentinel_conversation.system_prompt_addition}
      PROMPT
    end

    def build_prompt
      sentinel_conversation_entry.full_user_message
    end

    def messages
      @messages ||= sentinel_conversation.llm_messages
    end

  end
end
