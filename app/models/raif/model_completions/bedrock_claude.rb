# frozen_string_literal: true

class Raif::ModelCompletions::BedrockClaude < Raif::ModelCompletion

  def formatted_messages
    messages.map(&:symbolize_keys).map do |message|
      {
        role: message[:role],
        content: [{ text: message[:content] }]
      }
    end
  end

  def prompt_model_for_response!
    self.temperature ||= 0.7
    self.max_completion_tokens ||= 8192

    converse_params = {
      model_id: model_api_name,
      inference_config: { max_tokens: max_completion_tokens },
      messages: formatted_messages
    }
    converse_params[:system] = [{ text: system_prompt }] if system_prompt.present?

    # Handle JSON response formats
    if response_format_json?
      json_tool = create_json_tool
      converse_params[:tool_config] = {
        tools: [{ tool_spec: json_tool }],
        tool_choice: { tool: { name: json_tool[:name] } }
      }
    end

    client = Aws::BedrockRuntime::Client.new(region: Raif.config.aws_bedrock_region)
    resp = client.converse(converse_params)

    message = resp.output.message

    # Process the response based on format
    self.raw_response = if response_format_json?
      extract_json_response(message)
    else
      extract_text_response(message)
    end

    self.completion_tokens = resp.usage.output_tokens
    self.prompt_tokens = resp.usage.input_tokens
    self.total_tokens = resp.usage.total_tokens

    save!
  end

private

  def create_json_tool
    tool_name = "json_response"

    schema = if source&.respond_to?(:json_response_schema)
      # Use the source's schema if available
      source.json_response_schema
    else
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
      input_schema: { json: schema }
    }
  end

  def extract_json_response(message)
    return extract_text_response(message) if message.content.nil?

    # Look for tool_use blocks in the content array
    tool_response = message.content.find do |content|
      content.respond_to?(:tool_use) && content.tool_use.present? && content.tool_use.name == "json_response"
    end

    if tool_response&.tool_use
      JSON.generate(tool_response.tool_use.input)
    else
      extract_text_response(message)
    end
  end

  def extract_text_response(message)
    # Find the first text content block
    text_block = message.content&.find do |content|
      content.respond_to?(:text) && content.text.present?
    end

    text_block&.text
  end
end
