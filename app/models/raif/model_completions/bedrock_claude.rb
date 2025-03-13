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

    client = Aws::BedrockRuntime::Client.new(region: Raif.config.aws_bedrock_region)
    resp = client.converse(converse_params)

    message = resp.output.message
    response_text = message.content.first.text

    self.raw_response = response_text
    self.completion_tokens = resp.usage.output_tokens
    self.prompt_tokens = resp.usage.input_tokens
    self.total_tokens = resp.usage.total_tokens

    save!
  end
end
