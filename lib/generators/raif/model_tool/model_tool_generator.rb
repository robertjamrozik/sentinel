# frozen_string_literal: true

module Raif
  module Generators
    class ModelToolGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a new model tool for the LLM to invoke in app/models/sentinel/model_tools"

      def create_model_tool_file
        template "model_tool.rb.tt", File.join("app/models/sentinel/model_tools", "#{file_name}.rb")
      end

      def success_message
        say_status :success, "Model tool created successfully", :green
        say "\nYou can now implement your model tool in:"
        say "  app/models/sentinel/model_tools/#{file_name}.rb"
        say "\nImportant methods to implement:"
        say "  - example_model_invocation: Example of how to invoke this tool"
        say "  - tool_arguments_schema: JSON schema for the tool's arguments"
        say "  - tool_description: A brief description of what the tool does"
        say "  - process_invocation: The main method that executes the tool's functionality"
      end

    end
  end
end
