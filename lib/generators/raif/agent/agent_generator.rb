# frozen_string_literal: true

module Raif
  class AgentGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)
    desc "Creates a new Agent subclass in app/models/sentinel/agents"

    def create_agent
      template "agent.rb.tt", "app/models/sentinel/agents/#{file_name}.rb"
    end

  private

    def class_name
      name.classify
    end

    def file_name
      name.underscore
    end
  end
end
