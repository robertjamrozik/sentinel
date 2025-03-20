# frozen_string_literal: true

class Raif::Agent

  attr_accessor :task,
    :available_model_tools,
    :creator,
    :requested_language_key,
    :llm_model_key,
    :max_iterations

  def initialize(task:, tools:, creator:, requested_language_key: nil, llm_model_key: nil, max_iterations: 10)
    @task = task
    @available_model_tools = tools
    @creator = creator
    @requested_language_key = requested_language_key
    @llm_model_key = llm_model_key
    @max_iterations = max_iterations
  end

  # Runs the agent and returns a Raif::AgentInvocation.
  # If a block is given, it will be called each time a new entry is added to the agent's conversation history.
  # The block will receive the Raif::AgentInvocation and the new entry as arguments:
  # agent = Raif::Agent.new(task: task, tools: [Raif::ModelTools::WikipediaSearchTool, Raif::ModelTools::FetchUrlTool], creator: creator)
  # agent.run! do |agent_invocation, conversation_history_entry|
  #   Turbo::StreamsChannel.broadcast_append_to(
  #     :my_agent_channel,
  #     target: "agent-progress",
  #     partial: "my_partial_displaying_agent_progress",
  #     locals: { agent_invocation: agent_invocation, conversation_history_entry: conversation_history_entry }
  #   )
  # end
  #
  # The conversation_history_entry will be a hash with "role" and "content" keys:
  # { "role" => "assistant", "content" => "a message here" }
  #
  # @param block [Proc] Optional block to be called each time a new entry to the agent's conversation history is generated
  # @return [Raif::AgentInvocation] The agent invocation that was created and run
  def run!
    agent_invocation = Raif::AgentInvocation.new(
      task: task,
      available_model_tools: available_model_tools,
      system_prompt: system_prompt,
      creator: creator,
      requested_language_key: requested_language_key,
      llm_model_key: llm_model_key,
      max_iterations: max_iterations
    )

    agent_invocation.run! do |agent_invocation, entry|
      yield agent_invocation, entry if block_given?
    end

    agent_invocation
  end

  def system_prompt
    <<~PROMPT
      #{Raif.config.agent_system_prompt_intro}

      # Available Tools
      You have access to the following tools:
      #{available_model_tools.map(&:description_for_llm).join("\n---\n")}

      # Your Responses
      Your responses should follow this structure & format:
      <thought>Your step-by-step reasoning about what to do</thought>
      <action>JSON object with "tool" and "arguments" keys</action>
      <observation>Results from the tool, which will be provided to you</observation>
      ... (repeat Thought/Action/Observation as needed until the task is complete)
      <thought>Final reasoning based on all observations</thought>
      <answer>Your final response to the user</answer>

      # How to Use Tools
      When you need to use a tool:
      1. Identify which tool is appropriate for the task
      2. Format your tool call using JSON with the required arguments and place it in the <action> tag
      3. Here is an example: <action>{"tool": "tool_name", "arguments": {...}}</action>

      # Guidelines
      - Always think step by step
      - Use tools when appropriate, but don't use tools for tasks you can handle directly
      - Be concise in your reasoning but thorough in your analysis
      - If a tool returns an error, try to understand why and adjust your approach
      - If you're unsure about something, explain your uncertainty, but do not make things up
      - After each thought, make sure to also include an <action> or <answer>
      - Always provide a final answer that directly addresses the user's request

      Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.
    PROMPT
  end
end
