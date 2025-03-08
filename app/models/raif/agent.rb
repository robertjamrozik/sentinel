# frozen_string_literal: true

class Raif::Agent

  attr_accessor :task, :available_model_tools, :creator, :completion_args

  def initialize(task:, tools:, creator:, completion_args: nil)
    @task = task
    @available_model_tools = tools
    @creator = creator
    @conversation_history = []
    @completion_args = completion_args
  end

  def run
    agent_invocation = Raif::AgentInvocation.new(
      task: task,
      available_model_tools: available_model_tools,
      creator: creator
    )

    agent_invocation.run!
    agent_invocation
  end
end
