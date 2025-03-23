# frozen_string_literal: true

class Raif::Llms::AnthropicBase < Raif::Llm

  # def perform_model_completion!(model_completion)
  #   params = build_api_parameters(model_completion)
  #   make_api_call(params)

  #   # model_completion.raw_response = if model_completion.response_format_json?
  #   #   extract_json_response(resp)
  #   # else
  #   #   extract_text_response(resp)
  #   # end

  #   # extract_token_usage(resp)

  #   model_completion
  # end

protected

  def build_api_parameters(model_completion)
    raise NotImplementedError, "AnthropicBase subclasses must implement #build_api_parameters"
  end

  def extract_text_response(resp)
    raise NotImplementedError, "AnthropicBase subclasses must implement #extract_text_response"
  end

  def extract_json_response(resp)
    raise NotImplementedError, "AnthropicBase subclasses must implement #extract_json_response"
  end

  # Common method for creating JSON tool structure.
  # Subclasses may need to format the tool differently.
  def json_response_tool(schema:)
    {
      name: "json_response",
      description: "Generate a structured JSON response based on the provided schema.",
      schema: schema
    }
  end

end
