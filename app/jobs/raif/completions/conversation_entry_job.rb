# frozen_string_literal: true

module Raif
  class Completions::ConversationEntryJob < ApplicationJob

    before_enqueue do |job|
      conversation_entry = job.arguments.first[:conversation_entry]
      conversation_entry.update_columns(started_at: Time.current)
    end

    def perform(conversation_entry:)
      conversation_entry.run_completion
      conversation = conversation_entry.sentinel_conversation
      conversation_entry.broadcast_replace_to conversation

      Turbo::StreamsChannel.broadcast_action_to(
        conversation,
        action: :scroll_to_bottom,
        target: dom_id(conversation, :entries)
      )
    end

  end
end
