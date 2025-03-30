# frozen_string_literal: true

module Raif
  module Agents
    class NativeToolCallingAgent < Raif::Agent
      validate :ensure_llm_supports_native_tool_use

    private

      def native_model_tools
        available_model_tools
      end

      def process_iteration_model_completion(model_completion)
        if model_completion.parsed_response.present?
          add_conversation_history_entry({
            role: "assistant",
            content: model_completion.parsed_response
          })
        end

        tool_calls = model_completion.response_tool_calls

        # Check if any of the tool calls contains a final answer from the assistant
        answer_call = tool_calls.find{|call| call["name"] == "agent_final_answer" }
        if answer_call
          self.final_answer = answer_call["arguments"]["final_answer"]
          add_conversation_history_entry({ role: "assistant", content: "<answer>#{final_answer}</answer>" })
          return
        end

        if tool_calls.empty?
          add_conversation_history_entry({
            role: "assistant",
            content: "<observation>Error: No tool call found. I need make a tool call at each step. Available tools: #{available_model_tools_map.keys.join(", ")}</observation>"
          })
          return
        end

        tool_calls.each do |tool_call|
          tool_name = tool_call["name"]
          tool_arguments = tool_call["arguments"]

          # Add assistant's response to conversation history (without the actual tool calls)
          add_conversation_history_entry({
            role: "assistant",
            content: "<thought>I need to use the #{tool_name} tool to help with this task.</thought>"
          })

          # Add the tool call to conversation history
          add_conversation_history_entry({
            role: "assistant",
            content: "<action>#{JSON.pretty_generate(tool_call)}</action>"
          })

          # Find the tool class and process it
          tool_klass = available_model_tools_map[tool_name]

          # The model tried to use a tool that doesn't exist
          unless tool_klass
            add_conversation_history_entry({
              role: "assistant",
              content: "<observation>Error: Tool '#{tool_name}' not found. Available tools: #{available_model_tools_map.keys.join(", ")}</observation>"
            })
            next
          end

          # Process the tool and add observation to history
          tool_invocation = tool_klass.invoke_tool(tool_arguments: tool_arguments, source: self)
          observation = tool_klass.observation_for_invocation(tool_invocation)

          add_conversation_history_entry({
            role: "assistant",
            content: "<observation>#{observation}</observation>"
          })
        end
      end

      def build_system_prompt
        <<~PROMPT
          You are an AI agent that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool/function calls.

          At each step, you must:
          1. Clearly state your thought about what to do next.
          2. Choose and invoke exactly one tool/function call based on that thought.
          3. Observe the results of the tool/function call.
          4. Use the results to update your thought process.
          5. Repeat steps 1-4 until the task is complete.
          6. Provide a final answer to the user's request.

          For your final answer:
          - Use the agent_final_answer tool/function with your complete answer as the "final_answer" parameter.
          - Your answer should be comprehensive and directly address the user's request.

          Guidelines
          - Always think step by step
          - Be concise in your reasoning but thorough in your analysis
          - If a tool returns an error, try to understand why and adjust your approach
          - If you're unsure about something, explain your uncertainty, but do not make things up
          - Always provide a final answer that directly addresses the user's request

          Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.#{system_prompt_language_preference}
        PROMPT
      end

      def ensure_llm_supports_native_tool_use
        unless llm.supports_native_tool_use?
          errors.add(:base, "Raif::Agent#llm_model_key must use an LLM that supports native tool use")
        end
      end

    end
  end
end
