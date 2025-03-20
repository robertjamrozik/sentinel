# frozen_string_literal: true

class Raif::ModelCompletions::Anthropic < Raif::ModelCompletion
  def prompt_model_for_response!
    self.temperature ||= 0.7

    params = {
      model: model_api_name,
      messages: messages,
      temperature: temperature.to_f,
      max_tokens: max_completion_tokens
    }

    params[:system] = system_prompt if system_prompt

    # Handle JSON response formats
    if response_format_json?
      # Create a tool for structured JSON output
      json_tool = create_json_tool

      params[:tools] = [json_tool]
      # params[:tool_choice] = { type: "tool", name: json_tool[:name] }
    end

    resp = ::Anthropic.messages.create(**params)

    # Process the response based on format
    if response_format_json?
      # Extract the JSON content from the tool response
      tool_name = "json_response"
      tool_response = resp.body&.dig(:content)&.find do |content|
        content[:type] == "tool_use" && content[:name] == tool_name
      end

      self.raw_response = if tool_response
        JSON.generate(tool_response[:input])
      else
        extract_text_response(resp)
      end
    else
      self.raw_response = extract_text_response(resp)
    end

    self.completion_tokens = resp.body&.dig(:usage, :output_tokens)
    self.prompt_tokens = resp.body&.dig(:usage, :input_tokens)
    self.total_tokens = completion_tokens.present? && prompt_tokens.present? ? completion_tokens + prompt_tokens : nil

    save!
  end

private

  def create_json_tool
    tool_name = "json_response"

    schema = if source&.respond_to?(:json_response_schema)
      # Use the source's schema if available
      source.json_response_schema
    else
      # Improved default schema with a single response property
      {
        type: "object",
        properties: {
          response: {
            type: "string",
            description: "The complete response text"
          }
        },
        required: ["response"],
        additionalProperties: false,
        description: "Return a single text response containing your complete answer"
      }
    end

    {
      name: tool_name,
      description: "Generate a structured JSON response based on the provided schema.",
      input_schema: schema
    }
  end

  def extract_text_response(resp)
    resp.body&.dig(:content)&.first&.dig(:text)
  end
end
