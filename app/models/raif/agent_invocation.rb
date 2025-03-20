# frozen_string_literal: true

module Raif
  class AgentInvocation < ApplicationRecord
    include Raif::Concerns::HasLlm
    include Raif::Concerns::HasRequestedLanguage
    include Raif::Concerns::InvokesModelTools

    belongs_to :creator, polymorphic: true

    has_many :sentinel_model_completions, as: :source, dependent: :destroy, class_name: "Raif::ModelCompletion"

    boolean_timestamp :started_at
    boolean_timestamp :completed_at
    boolean_timestamp :failed_at

    validates :task, presence: true
    validates :system_prompt, presence: true
    validates :max_iterations, presence: true, numericality: { greater_than: 0 }

    attr_accessor :on_conversation_history_entry

    def run!(&block)
      self.on_conversation_history_entry = block_given? ? block : nil
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

      add_conversation_history_entry({ role: "user", content: task })

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

        model_completion = llm.chat(messages: conversation_history, source: self, system_prompt: system_prompt)
        agent_step = Raif::AgentStep.new(model_response_text: model_completion.raw_response)
        logger.debug <<~DEBUG
          --------------------------------
          Agent iteration #{iteration_count}
          Messages:
          #{JSON.pretty_generate(conversation_history)}

          Response:
          #{model_completion.raw_response}
          --------------------------------
        DEBUG

        # Add the thought to conversation history
        if agent_step.thought
          add_conversation_history_entry({ role: "assistant", content: "<thought>#{agent_step.thought}</thought>" })
        end

        # If there's an answer, we're done
        if agent_step.answer
          self.final_answer = agent_step.answer
          add_conversation_history_entry({ role: "assistant", content: "<answer>#{agent_step.answer}</answer>" })
          break
        end

        # If there's an action, execute it
        next unless agent_step.action

        add_conversation_history_entry({ role: "assistant", content: "<action>#{agent_step.action}</action>" })

        if agent_step.parsed_action && agent_step.parsed_action["tool"] && agent_step.parsed_action["arguments"]
          process_action(agent_step.parsed_action)
        else
          # No action specified
          add_conversation_history_entry({
            role: "user",
            content: "<observation>Error: No valid action specified. Please provide a valid action, formatted as a JSON object with 'tool' and 'arguments' keys.</observation>" # rubocop:disable Layout/LineLength
          })
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
        add_conversation_history_entry({
          role: "user",
          content: "<observation>Error: Tool '#{tool_name}' not found. Available tools: #{available_model_tools_map.keys.join(", ")}</observation>"
        })
        return
      end

      tool_invocation = tool_klass.invoke_tool(tool_arguments: tool_arguments, source: self)
      observation = tool_klass.observation_for_invocation(tool_invocation)

      # Add the tool invocation to conversation history
      add_conversation_history_entry({
        role: "user",
        content: "<observation>#{observation}</observation>"
      })
    end

    def add_conversation_history_entry(entry)
      conversation_history << entry.stringify_keys

      on_conversation_history_entry.call(self, entry) if on_conversation_history_entry.present?
    end

  end
end
