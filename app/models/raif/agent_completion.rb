# frozen_string_literal: true

module Raif
  class AgentCompletion < Raif::Completion
    attr_accessor :agent, :conversation_history

    llm_response_format :text
    llm_completion_args :agent, :conversation_history

    def initialize(agent:, conversation_history: [], **args)
      super(**args)
      @agent = agent
      @conversation_history = conversation_history || []
    end

    def build_prompt
      agent.task
    end

    def build_system_prompt
      sp = agent.system_prompt
      sp += "\n\n" + "You're collaborating with teammate who speaks #{requested_language_name}. For your final answer, please respond in #{requested_language_name}." # rubocop:disable Layout/LineLength
      sp
    end

    def messages
      messages = []

      # Add conversation history
      conversation_history.each do |entry|
        messages << { "role" => entry[:role], "content" => entry[:content] }
      end

      # Add the current prompt
      messages << { "role" => "user", "content" => prompt }

      messages
    end

    def extract_thought_action_answer
      response_text = response.to_s

      thought_match = response_text.match(%r{<thought>(.*?)</thought>}m)
      action_match = response_text.match(%r{<action>(.*?)</action>}m)
      answer_match = response_text.match(%r{<answer>(.*?)</answer>}m)

      {
        thought: thought_match ? thought_match[1].strip : nil,
        action: action_match ? parse_action(action_match[1].strip) : nil,
        answer: answer_match ? answer_match[1].strip : nil
      }
    end

  private

    def parse_action(action_text)
      JSON.parse(action_text)
    rescue JSON::ParserError
      nil
    end
  end
end
