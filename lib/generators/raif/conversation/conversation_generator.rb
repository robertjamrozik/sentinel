# frozen_string_literal: true

module Raif
  module Generators
    class ConversationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a new conversation type in the app/models/sentinel/conversations directory"

      def create_application_conversation
        template "application_conversation.rb.tt",
          "app/models/sentinel/application_conversation.rb" unless File.exist?("app/models/sentinel/application_conversation.rb")
      end

      def create_conversation_file
        template "conversation.rb.tt", File.join("app/models/sentinel/conversations", "#{file_name}.rb")
      end

      def create_directory
        empty_directory "app/models/sentinel/conversations" unless File.directory?("app/models/sentinel/conversations")
      end

      def success_message
        say_status :success, "Conversation type created successfully", :green
        say "\nYou can now implement your conversation type in:"
        say "  app/models/sentinel/conversations/#{file_name}.rb\n\n"
        say "\nDon't forget to add it to the config.conversation_types in your Raif configuration"
        say "For example: config.conversation_types += ['Raif::Conversations::#{class_name}']\n\n"
      end
    end
  end
end
