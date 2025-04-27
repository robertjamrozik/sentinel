# frozen_string_literal: true

class Raif::ModelTool
  include Raif::Concerns::JsonSchemaDefinition

  delegate :tool_name, :tool_description, :tool_arguments_schema, to: :class

  # The description of the tool that will be provided to the model
  # when giving it a list of available tools.
  def self.description_for_llm
    <<~DESCRIPTION
      Name: #{tool_name}
      Description: #{tool_description}
      Arguments Schema:
      #{JSON.pretty_generate(tool_arguments_schema)}
      Example Usage:
      #{JSON.pretty_generate(example_model_invocation)}
    DESCRIPTION
  end

  # The name of the tool as it will be provided to the model & used in the model invocation.
  # Default for something like Raif::ModelTools::WikipediaSearch would be "wikipedia_search"
  def self.tool_name
    name.split("::").last.underscore
  end

  def self.tool_description
    raise NotImplementedError, "#{self.class.name}#tool_description is not implemented"
  end

  def self.example_model_invocation
    raise NotImplementedError, "#{self.class.name}#example_model_invocation is not implemented"
  end

  def self.process_invocation(invocation)
    raise NotImplementedError, "#{self.class.name}#process_invocation is not implemented"
  end

  def self.invocation_partial_name
    name.gsub("Raif::ModelTools::", "").underscore
  end

  def self.define_tool_arguments_schema(&block)
    json_schema_definition(:tool_arguments, &block)
  end

  def self.tool_arguments_schema
    if schema_defined?(:tool_arguments)
      schema_for(:tool_arguments)
    else
      raise NotImplementedError,
        "#{self.class.name} must define tool arguments schema via define_tool_arguments_schema or override #{self.class.name}.tool_arguments_schema"
    end
  end

  def self.renderable?
    true
  end

  def self.triggers_observation_to_model?
    false
  end

  def self.invoke_tool(tool_arguments:, source:)
    tool_invocation = Raif::ModelToolInvocation.new(
      source: source,
      tool_type: name,
      tool_arguments: tool_arguments
    )

    ActiveRecord::Base.transaction do
      tool_invocation.save!
      process_invocation(tool_invocation)
      tool_invocation.completed!
    end

    tool_invocation
  rescue StandardError => e
    tool_invocation.failed!
    raise e
  end

end
