# frozen_string_literal: true

class Raif::AgentStep
  attr_reader :model_response_text

  def initialize(model_response_text:)
    @model_response_text = model_response_text
  end

  def thought
    @thought ||= extract_tag_content("thought")
  end

  def action
    @action ||= extract_tag_content("action")
  end

  def parsed_action
    @parsed_action ||= begin
      JSON.parse(action)
    rescue JSON::ParserError
      nil
    end
  end

  def answer
    @answer ||= extract_tag_content("answer")
  end

private

  def extract_tag_content(tag_name)
    match = model_response_text.match(%r{<#{tag_name}>(.*?)</#{tag_name}>}m)
    match ? match[1].strip : nil
  end
end
