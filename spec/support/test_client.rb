# frozen_string_literal: true

class Raif::TestClient
  attr_accessor :chat_handler

  def chat(messages:, system_prompt: nil)
    {
      response: chat_handler.call(messages),
      prompt_tokens: rand(1..4),
      completion_tokens: rand(10..30)
    }
  end
end
