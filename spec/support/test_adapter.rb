# frozen_string_literal: true

class Raif::TestAdapter < Raif::ApiAdapters::Base
  attr_accessor :chat_handler

  def chat(messages:, system_prompt: nil)
    Raif::ModelResponse.new(
      messages: messages,
      system_prompt: system_prompt,
      raw_response: chat_handler.call(messages),
      prompt_tokens: rand(1..4),
      completion_tokens: rand(10..30),
      total_tokens: rand(14..34)
    )
  end
end
