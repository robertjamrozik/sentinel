# frozen_string_literal: true

class Raif::Llms::OpenAi < Raif::Llm
  def perform_model_completion!(model_completion)
    parameters = build_chat_parameters(model_completion)
    client = OpenAI::Client.new
    resp = client.chat(parameters: parameters)

    model_completion.update!(
      raw_response: resp.dig("choices", 0, "message", "content"),
      completion_tokens: resp["usage"]["completion_tokens"],
      prompt_tokens: resp["usage"]["prompt_tokens"],
      total_tokens: resp["usage"]["total_tokens"],
      response_format_parameter: parameters.dig(:response_format, :type)
    )

    model_completion
  end

private

  def build_chat_parameters(model_completion)
    formatted_system_prompt = model_completion.system_prompt.to_s.strip

    # If the response format is JSON, we need to include "as json" in the system prompt.
    # OpenAI requires this and will throw an error if it's not included.
    if model_completion.response_format_json?
      # Ensure system prompt ends with a period if not empty
      if formatted_system_prompt.present? && !formatted_system_prompt.end_with?(".", "?", "!")
        formatted_system_prompt += "."
      end
      formatted_system_prompt += " Return your response as JSON."
      formatted_system_prompt.strip!
    end

    messages = model_completion.messages
    messages_with_system = if !formatted_system_prompt.empty?
      [{ "role" => "system", "content" => formatted_system_prompt }] + messages
    else
      messages
    end

    parameters = {
      model: api_name,
      messages: messages_with_system,
      temperature: (model_completion.temperature || default_temperature).to_f
    }

    # Add response format if needed
    response_format = determine_response_format(model_completion)
    parameters[:response_format] = response_format if response_format

    parameters
  end

  def determine_response_format(model_completion)
    # Only configure response format for JSON outputs
    return unless model_completion.response_format_json?

    if model_completion.json_response_schema.present? && supports_structured_outputs?
      {
        type: "json_schema",
        json_schema: {
          name: "json_response_schema",
          strict: true,
          schema: model_completion.json_response_schema
        }
      }
    else
      # Default JSON mode for OpenAI models that don't support structured outputs or no schema is provided
      { type: "json_object" }
    end
  end

  def supports_structured_outputs?
    # Not all OpenAI models support structured outputs:
    # https://platform.openai.com/docs/guides/structured-outputs?api-mode=chat#supported-models
    provider_settings[:supports_structured_outputs]
  end
end
