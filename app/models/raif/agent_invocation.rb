# frozen_string_literal: true

module Raif
  class AgentInvocation < ApplicationRecord
    include Raif::Concerns::HasLlm
    include Raif::Concerns::HasRequestedLanguage
    include Raif::Concerns::InvokesModelTools

    belongs_to :creator, polymorphic: true

    has_many :model_responses, as: :source, dependent: :destroy

    boolean_timestamp :started_at
    boolean_timestamp :completed_at
    boolean_timestamp :failed_at

    validates :task, presence: true
    validates :system_prompt, presence: true
    validates :max_iterations, presence: true, numericality: { greater_than: 0 }

    def run!
      self.started_at = Time.current

      # If they invoked the agent with a requested language, add that to the system prompt
      # so the model responds in that language.
      if requested_language_key.present? && !system_prompt.include?(system_prompt_language_preference)
        self.system_prompt = <<~SYSTEM_PROMPT
          #{system_prompt}

          #{system_prompt_language_preference}
        SYSTEM_PROMPT
      end

      save!

      conversation_history << { role: "user", content: task }

      while iteration_count < max_iterations
        update_columns(iteration_count: iteration_count + 1)

        if iteration_count == 1
          logger.debug <<~DEBUG
            --------------------------------
            Starting Agent Run
            --------------------------------
            System Prompt:
            #{system_prompt}
          DEBUG
        end

        model_response = llm.chat(messages: conversation_history, source: self, system_prompt: system_prompt)
        agent_step = Raif::AgentStep.new(model_response_text: model_response.raw_response)
        logger.debug <<~DEBUG
          --------------------------------
          Agent iteration #{iteration_count}
          Messages:
          #{JSON.pretty_generate(conversation_history)}

          Response:
          #{model_response.raw_response}
          --------------------------------
        DEBUG

        # Add the thought to conversation history
        if agent_step.thought
          conversation_history << { role: "assistant", content: "<thought>#{agent_step.thought}</thought>" }
        end

        # If there's an answer, we're done
        if agent_step.answer
          self.final_answer = agent_step.answer
          conversation_history << { role: "assistant", content: "<answer>#{agent_step.answer}</answer>" }
          break
        end

        # If there's an action, execute it
        next unless agent_step.action

        conversation_history << { role: "assistant", content: "<action>#{agent_step.action}</action>" }

        if agent_step.action["tool"] && agent_step.action["arguments"]
          process_action(agent_step.action)
        else
          # No action specified
          conversation_history << {
            role: "user",
            content: "<observation>Error: No valid action specified. Please provide a valid action with 'tool' and 'arguments' keys.</observation>"
          }
        end
      end

      completed!
      final_answer
    end

    def process_action(action)
      tool_name = action["tool"]
      tool_arguments = action["arguments"]

      # Find the tool class
      tool_klass = available_model_tools_map[tool_name]

      # The model tried to use a tool that doesn't exist
      unless tool_klass
        conversation_history << {
          role: "user",
          content: "<observation>Error: Tool '#{tool_name}' not found. Available tools: #{available_model_tools_map.keys.join(", ")}</observation>"
        }
        return
      end

      tool_invocation = tool_klass.invoke_tool(tool_arguments: tool_arguments, source: self)
      observation = tool_klass.observation_for_invocation(tool_invocation)

      # Add the tool invocation to conversation history
      conversation_history << {
        role: "user",
        content: "<observation>#{observation}</observation>"
      }
    end

  end
end
