# frozen_string_literal: true

class Raif::ModelTools::AgentFinalAnswer < Raif::ModelTool
  define_tool_arguments_schema do
    string "final_answer", description: "Your complete and final answer to the user's question or task"
  end

  def self.example_model_invocation
    {
      "name" => tool_name,
      "arguments" => { "final_answer": "The answer to the user's question or task" }
    }
  end

  def self.tool_description
    "Provide your final answer to the user's question or task"
  end

  def self.observation_for_invocation(tool_invocation)
    return "No answer provided" unless tool_invocation.result.present?

    tool_invocation.result["final_answer"]
  end

  def self.process_invocation(tool_invocation)
    tool_invocation.update!(
      result: {
        final_answer: tool_invocation.tool_arguments["final_answer"]
      }
    )

    tool_invocation.result
  end

end
