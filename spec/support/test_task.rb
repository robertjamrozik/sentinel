# frozen_string_literal: true

class Raif::TestTask < Raif::Task
  llm_temperature 0.5

  def build_prompt
    "Tell me a joke"
  end

  def build_system_prompt
    super + "\nYou are also good at telling jokes."
  end
end

class Raif::TestJsonTask < Raif::Task
  llm_response_format :json
  llm_temperature 0.75

  def self.json_response_schema
    {
      type: "object",
      additionalProperties: false,
      required: ["joke", "answer"],
      properties: {
        joke: { type: "string" },
        answer: { type: "string" }
      }
    }
  end

  def build_prompt
    "Tell me a joke"
  end

  def build_system_prompt
    super + "\nYou are also good at telling jokes. Your response should be a JSON object with the following keys: joke, answer."
  end
end

class Raif::TestHtmlTask < Raif::Task
  llm_response_format :html

  def build_prompt
    "Tell me a joke"
  end

  def build_system_prompt
    super + "\nYou are also good at telling jokes. Your response should be an HTML snippet that is formatted with basic HTML tags."
  end
end
