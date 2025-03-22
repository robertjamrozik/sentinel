# frozen_string_literal: true

module Raif
  module AgentInvocations
    class ResearchAgent < Raif::AgentInvocation
      # If you want to always include a certain set of model tools with this agent type,
      # uncomment this callback to populate the available_model_tools attribute with your desired model tools.
      # before_create -> {
      #   self.available_model_tools ||= [
      #     Raif::ModelTools::WikipediaSearchTool,
      #     Raif::ModelTools::FetchUrlTool
      #   ]
      # }

      # Customize the system prompt intro for this specific agent type
      # def system_prompt_intro
      #   <<~PROMPT
      #     You are an intelligent assistant that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool calls.
      #     You are an expert in researching and synthesizing information from Wikipedia.
      #   PROMPT
      # end

      # Or if needed, you can override the entire system prompt. Below is the default implementation.
      # def build_system_prompt
      #   <<~PROMPT
      #     #{system_prompt_intro}
      #
      #    # Available Tools
      #    You have access to the following tools:
      #    #{available_model_tools_map.values.map(&:description_for_llm).join("\n---\n")}
      #
      #    # Your Responses
      #    Your responses should follow this structure & format:
      #    <thought>Your step-by-step reasoning about what to do</thought>
      #    <action>JSON object with "tool" and "arguments" keys</action>
      #    <observation>Results from the tool, which will be provided to you</observation>
      #    ... (repeat Thought/Action/Observation as needed until the task is complete)
      #    <thought>Final reasoning based on all observations</thought>
      #    <answer>Your final response to the user</answer>
      #
      #     # How to Use Tools
      #     When you need to use a tool:
      #     1. Identify which tool is appropriate for the task
      #     2. Format your tool call using JSON with the required arguments and place it in the <action> tag
      #     3. Here is an example: <action>{"tool": "tool_name", "arguments": {...}}</action>
      #
      #     # Guidelines
      #     - Always think step by step
      #     - Use tools when appropriate, but don't use tools for tasks you can handle directly
      #     - Be concise in your reasoning but thorough in your analysis
      #     - If a tool returns an error, try to understand why and adjust your approach
      #     - If you're unsure about something, explain your uncertainty, but do not make things up
      #     - After each thought, make sure to also include an <action> or <answer>
      #     - Always provide a final answer that directly addresses the user's request
      #
      #     Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.#{system_prompt_language_preference}
      #   PROMPT
      # end

    end
  end
end
