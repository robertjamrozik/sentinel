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
      end

    end
  end
end
