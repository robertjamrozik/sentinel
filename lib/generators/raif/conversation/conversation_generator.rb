# frozen_string_literal: true

module Raif
  module Generators
    class ConversationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a new conversation subclass in the app/models/sentinel/conversations directory"

      def create_conversation_file
        template "conversation.rb.tt", File.join("app/models/sentinel/conversations", "#{file_name}.rb")
      end

      def create_directory
        empty_directory "app/models/sentinel/conversations" unless File.directory?("app/models/sentinel/conversations")
      end

      def success_message
        say_status :success, "Conversation subclass created successfully", :green
        say "\nYou can now implement your conversation subclass in:"
        say "  app/models/sentinel/conversations/#{file_name}.rb"
        say "\nImportant methods to customize:"
        say "  - build_system_prompt: Customize the system prompt for this conversation type"
        say "  - initial_chat_message: Set the initial message shown to the user"
      end
    end
  end
end
