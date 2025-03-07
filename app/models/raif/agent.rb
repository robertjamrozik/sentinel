# frozen_string_literal: true

class Raif::Agent

  attr_accessor :task, :available_tools, :creator, :completion_args
  attr_reader :conversation_history, :final_answer

  def initialize(task:, tools:, creator:, completion_args: nil)
    @task = task
    @available_tools = tools
    @creator = creator
    @conversation_history = []
    @final_answer = nil
    @completion_args = completion_args
  end

  def run
    max_iterations = 10
    iteration = 0

    while iteration < max_iterations
      iteration += 1

      # Create and run a completion
      completion = Raif::AgentCompletion.run(
        creator: creator,
        agent: self,
        available_model_tools: available_tools,
        conversation_history: conversation_history,
        **completion_args
      )

      if iteration == 1
        puts "\n\n"
        puts "--------------------------------"
        puts "Starting Agent Run"
        puts "--------------------------------"
        puts "System Prompt:"
        puts completion.system_prompt
      end

      puts "\n"
      puts "--------------------------------"
      puts "Running Agent iteration #{iteration}"
      puts "Prompt:\n#{completion.prompt}"
      puts "Response:\n#{completion.response}"
      puts "--------------------------------"
      puts "\n\n\n"

      # Extract thought, action, and answer from the completion
      thought = completion.extract_thought
      action = completion.extract_action
      answer = completion.extract_answer

      # Add the thought to conversation history
      if thought
        conversation_history << { role: "assistant", content: "<thought>#{thought}</thought>" }
      end

      # If there's an answer, we're done
      if answer
        @final_answer = answer
        conversation_history << { role: "assistant", content: "<answer>#{answer}</answer>" }
        break
      end

      # If there's an action, execute it
      if action && action["tool"] && action["arguments"]
        tool_name = action["tool"]
        arguments = action["arguments"]

        # Find the tool class
        debugger
        tool_class_name = available_tools.find { |t| t.constantize.tool_name == tool_name }

        if tool_class_name
          # Create a tool invocation
          tool_class = tool_class_name.constantize

          # Execute the tool
          observation = begin
            tool_invocation = Raif::ModelToolInvocation.new(
              sentinel_completion: completion,
              tool_type: tool_class_name,
              tool_arguments: arguments
            )

            tool_instance = tool_class.new
            tool_instance.process_invocation(tool_invocation)

            # Return a string representation of the result
            "Tool executed successfully: #{tool_invocation.inspect}"
          rescue StandardError => e
            "Error: #{e.message}"
          end

          # Add the action and observation to conversation history
          conversation_history << {
            role: "assistant",
            content: "<action>#{result[:action].to_json}</action>"
          }

          conversation_history << {
            role: "user",
            content: "<observation>#{observation}</observation>"
          }
        else
          # Tool not found
          conversation_history << {
            role: "user",
            content: "<observation>Error: Tool '#{tool_name}' not found. Available tools: #{available_tools.map(&:tool_name).join(", ")}</observation>"
          }
        end
      else
        # No action specified
        conversation_history << {
          role: "user",
          content: "<observation>Error: No valid action specified. Please provide a valid action with 'tool' and 'arguments' keys.</observation>"
        }
      end
    end

    # Return the final answer
    @final_answer
  end

  def system_prompt
    <<~PROMPT
      You are an intelligent assistant that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool calls.

      # Available Tools
      You have access to the following tools:
      #{available_tools.map(&:description_for_llm).join("\n---\n")}

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
      - Always provide a final answer that directly addresses the user's request

      Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.
    PROMPT
  end
end
