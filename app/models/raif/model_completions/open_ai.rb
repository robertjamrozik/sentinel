# frozen_string_literal: true

class Raif::ModelCompletions::OpenAi < Raif::ModelCompletion
  def prompt_model_for_response!
    self.temperature ||= 0.7

    messages_with_system = [{ role: "system", content: system_prompt }] + messages if system_prompt

    client = OpenAI::Client.new
    resp = client.chat(
      parameters: {
        model: model_api_name,
        messages: messages_with_system,
        temperature: temperature,
      }
    )

    self.raw_response = resp.dig("choices", 0, "message", "content")
    self.completion_tokens = resp["usage"]["completion_tokens"]
    self.prompt_tokens = resp["usage"]["prompt_tokens"]
    self.total_tokens = resp["usage"]["total_tokens"]

    save!
  end
end
