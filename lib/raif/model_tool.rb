# frozen_string_literal: true

class Raif::ModelTool

  delegate :tool_name, :tool_description, to: :class

  def self.tool_name
    name_key = name.split("::").last.underscore
    I18n.t("sentinel.model_tools.#{name_key}.name", default: name_key)
  end

  def self.tool_description
    I18n.t("sentinel.model_tools.#{name.underscore.gsub("/", ".")}.description")
  end

  def self.invoke_tool(tool_arguments:, completion:)
    tool_instance = new
    tool_arguments = tool_instance.clean_tool_arguments(tool_arguments)

    tool_invocation = Raif::ModelToolInvocation.new(
      sentinel_completion: completion,
      tool_type: name,
      tool_arguments: tool_arguments
    )

    ActiveRecord::Base.transaction do
      tool_invocation.save!
      tool_instance.process_invocation(tool_invocation)
    end

    tool_invocation
  end

  def process_invocation(invocation)
    raise NotImplementedError, "#{self.class.name}#process_invocation is not implemented"
  end

  def invocation_partial_name
    self.class.name.gsub("Raif::ModelTools::", "").underscore
  end

  def clean_tool_arguments(tool_arguments)
    # By default, we do nothing to the tool arguments. Subclasses can override to clean as desired.
    tool_arguments
  end

  def tool_arguments_schema
    # implement in subclasses
  end

  def renderable?
    true
  end

end
