# frozen_string_literal: true

class Raif::ModelCompletions::OpenAi < Raif::ModelCompletion
  def prompt_model_for_response!
    self.temperature ||= 0.7

    parameters = build_chat_parameters

    client = OpenAI::Client.new
    resp = client.chat(parameters: parameters)

    self.raw_response = resp.dig("choices", 0, "message", "content")
    self.completion_tokens = resp["usage"]["completion_tokens"]
    self.prompt_tokens = resp["usage"]["prompt_tokens"]
    self.total_tokens = resp["usage"]["total_tokens"]

    save!
  end

private

  def build_chat_parameters
    messages_with_system = if system_prompt
      [{ "role" => "system", "content" => system_prompt }] + messages
    else
      messages
    end

    parameters = {
      model: model_api_name,
      messages: messages_with_system,
      temperature: temperature.to_f,
    }

    # Add response format if needed
    response_format = determine_response_format
    parameters[:response_format] = response_format if response_format

    parameters
  end

  def determine_response_format
    # Only configure response format for JSON outputs
    return unless response_format_json?

    # Use json_schema when we have a schema available
    if source&.respond_to?(:json_response_schema) && supports_structured_outputs?
      # We have a schema available - use json_schema
      {
        type: "json_schema",
        json_schema: source.json_response_schema
      }
    else
      # Default JSON mode for all OpenAI models
      { type: "json_object" }
    end
  end

  def supports_structured_outputs?
    # Not all OpenAI models support structured outputs:
    # https://platform.openai.com/docs/guides/structured-outputs?api-mode=chat#supported-models
    true
  end
end
