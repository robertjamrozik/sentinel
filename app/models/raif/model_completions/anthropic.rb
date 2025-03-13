# frozen_string_literal: true

class Raif::ModelCompletions::Anthropic < Raif::ModelCompletion

  def prompt_model_for_response!
    self.temperature ||= 0.7
    self.max_completion_tokens ||= 8192

    params = {
      model: model_api_name,
      messages: messages,
      temperature: temperature,
      max_tokens: max_completion_tokens
    }

    params[:system] = system_prompt if system_prompt
    resp = ::Anthropic.messages.create(**params)

    self.raw_response = resp.body&.dig(:content)&.first&.dig(:text)
    self.completion_tokens = resp.body&.dig(:usage, :output_tokens)
    self.prompt_tokens = resp.body&.dig(:usage, :input_tokens)
    self.total_tokens = completion_tokens.present? && prompt_tokens.present? ? completion_tokens + prompt_tokens : nil

    save!
  end
end
