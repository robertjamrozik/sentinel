# frozen_string_literal: true

module Raif
  module Generators
    class AgentInvocationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a new AgentInvocation subclass in app/models/sentinel/agent_invocations"

      def create_agent_invocation_file
        template "agent_invocation.rb.tt", File.join("app/models/sentinel/agent_invocations", "#{file_name}.rb")
      end

      def success_message
        say_status :success, "AgentInvocation subclass created successfully", :green
        say "\nYou can now customize your agent invocation in:"
        say "  app/models/sentinel/agent_invocations/#{file_name}.rb"
        say "\nDon't forget to add it to the config.agent_invocation_types in your Raif configuration"
        say "For example: config.agent_invocation_types += ['Raif::AgentInvocations::#{class_name}']\n\n"
      end
    end
  end
end
