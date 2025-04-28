# frozen_string_literal: true

class Raif::TestModelTool < Raif::ModelTool
  tool_arguments_schema do
    array :items do
      object do
        string :title, description: "The title of the item"
        string :description
      end
    end
  end

  example_model_invocation do
    {
      "name": tool_name,
      "arguments": { "items": [{ "title": "foo", "description": "bar" }] }
    }
  end

  def self.process_invocation(tool_arguments)
  end

  tool_description do
    "Mock Tool Description"
  end

  def self.observation_for_invocation(tool_invocation)
    return if tool_invocation.result.blank?

    "Mock Observation for #{tool_invocation.id}. Result was: #{tool_invocation.result["status"]}"
  end
end
