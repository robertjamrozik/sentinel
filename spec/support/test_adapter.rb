# frozen_string_literal: true

class Raif::ApiAdapters::Test < Raif::ApiAdapters::Base
  attr_accessor :chat_handler

  def chat(messages:, system_prompt: nil)
    if chat_handler.blank?
      raise "No chat handler set for Raif test adapter."
    end

    unless chat_handler.respond_to?(:call)
      raise "Raif test chat handler must respond to #call."
    end

    Raif::ModelCompletion.new(
      messages: messages,
      system_prompt: system_prompt,
      raw_response: chat_handler.call(messages),
      prompt_tokens: rand(1..4),
      completion_tokens: rand(10..30),
      total_tokens: rand(14..34)
    )
  end
end

unless Raif.available_llm_keys.include?(:sentinel_test_adapter)
  Raif.register_llm(
    key: :sentinel_test_adapter,
    api_name: "sentinel_test_adapter",
    api_adapter: Raif::ApiAdapters::Test
  )
end
