# frozen_string_literal: true

Raif.configure do |config|
  # config.conversations_controller = "ConversationsController"
  # config.conversation_entries_controller = "ConversationEntriesController"

  config.authorize_controller_action = ->() { true }
  config.authorize_admin_controller_action = ->() { true }
end
