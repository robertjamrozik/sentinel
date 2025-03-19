# frozen_string_literal: true

module Raif
  module Shared
    module ConversationsHelper

      def sentinel_conversation(conversation)
        render "sentinel/conversations/full_conversation", conversation: conversation
      end

    end
  end
end
