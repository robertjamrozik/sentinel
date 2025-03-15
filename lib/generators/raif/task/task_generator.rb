# frozen_string_literal: true

module Raif
  module Generators
    class TaskGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :response_format,
        type: :string,
        default: "text",
        desc: "Response format for the task (text, html, or json)"

      def create_application_task
        template "application_task.rb.tt", "app/models/sentinel/application_task.rb" unless File.exist?("app/models/sentinel/application_task.rb")
      end

      def create_task_file
        template "task.rb.tt", File.join("app/models/sentinel/tasks", class_path, "#{file_name}_task.rb")
      end

    private

      def task_class_name
        "#{class_name}Task"
      end
    end
  end
end
