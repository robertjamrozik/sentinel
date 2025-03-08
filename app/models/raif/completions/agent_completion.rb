# frozen_string_literal: true

module Raif::Completions
  class AgentCompletion < Raif::Completion
    belongs_to :sentinel_agent_invocation, class_name: "Raif::AgentInvocation"

    llm_response_format :text

    def build_prompt
      # no-op. Agent completions overrides messages method to provide prompt
    end

    def messages
      sentinel_agent_invocation.conversation_history
    end

    def build_system_prompt
      sp = sentinel_agent_invocation.system_prompt

      if requested_language_key.present?
        sp += "\nYou're collaborating with teammate who speaks #{requested_language_name}. For your final answer, please respond in #{requested_language_name}." # rubocop:disable Layout/LineLength
      end

      sp
    end

    def extract_thought
      response_text = response.to_s
      thought_match = response_text.match(%r{<thought>(.*?)</thought>}m)
      thought_match ? thought_match[1].strip : nil
    end

    def extract_action
      response_text = response.to_s
      action_match = response_text.match(%r{<action>(.*?)</action>}m)
      action_match ? parse_action(action_match[1].strip) : nil
    end

    def extract_answer
      response_text = response.to_s
      answer_match = response_text.match(%r{<answer>(.*?)</answer>}m)
      answer_match ? answer_match[1].strip : nil
    end

    def process_model_tool_invocations
      # action = extract_action
      # return unless action.present?

      # debugger
      # action_json = JSON.parse(action)

      # tool_klass = available_model_tools_map[action_json["tool"]]
      # return unless tool_klass

      # debugger
      # tool_klass.invoke_tool(tool_arguments: action_json["arguments"], completion: self)
    end

    def parse_action(action_text)
      JSON.parse(action_text)
    rescue JSON::ParserError
      nil
    end
  end
end
