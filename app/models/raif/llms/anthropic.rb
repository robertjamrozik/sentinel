# frozen_string_literal: true

class Raif::Llms::Anthropic < Raif::Llms::AnthropicBase

protected

  def perform_model_completion!(model_completion)
    params = build_api_parameters(model_completion)
    resp = ::Anthropic.messages.create(**params)

    model_completion.raw_response = if model_completion.response_format_json?
      extract_json_response(resp)
    else
      extract_text_response(resp)
    end

    model_completion.completion_tokens = resp.body&.dig(:usage, :output_tokens)
    model_completion.prompt_tokens = resp.body&.dig(:usage, :input_tokens)
    model_completion.save!

    model_completion
  end

  def build_api_parameters(model_completion)
    params = {
      model: model_completion.model_api_name,
      messages: model_completion.messages,
      temperature: (model_completion.temperature || default_temperature).to_f,
      max_tokens: model_completion.max_completion_tokens || default_max_completion_tokens
    }

    params[:system] = model_completion.system_prompt if model_completion.system_prompt.present?

    # Handle JSON response formats
    if model_completion.response_format_json? && model_completion.json_response_schema.present?
      # Create a tool for structured JSON output
      json_tool = format_json_tool(json_response_tool(schema: model_completion.json_response_schema))

      params[:tools] = [json_tool]
      # params[:tool_choice] = { type: "tool", name: json_tool[:name] }
    end

    params
  end

  def extract_text_response(resp)
    resp.body&.dig(:content)&.first&.dig(:text)
  end

  def extract_json_response(resp)
    return extract_text_response(resp) if resp.body&.dig(:content).nil?

    # Look for tool_use blocks in the content array
    tool_name = "json_response"
    tool_response = resp.body&.dig(:content)&.find do |content|
      content[:type] == "tool_use" && content[:name] == tool_name
    end

    if tool_response
      JSON.generate(tool_response[:input])
    else
      extract_text_response(resp)
    end
  end

private

  def format_json_tool(tool_base)
    {
      name: tool_base[:name],
      description: tool_base[:description],
      input_schema: tool_base[:schema]
    }
  end
end
