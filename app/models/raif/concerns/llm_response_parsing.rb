# frozen_string_literal: true

module Raif::Concerns::LlmResponseParsing
  extend ActiveSupport::Concern

  included do
    normalizes :raw_response, with: ->(text){ text&.strip }

    enum :response_format, Raif::Llm.valid_response_formats, prefix: true

    validates :response_format, presence: true, inclusion: { in: response_formats.keys }
  end

  # Parses the response from the LLM into a structured format, based on the response_format.
  #
  # @return [Object] The parsed response.
  def parsed_response
    @parsed_response ||= if response_format_json?
      json = raw_response.gsub("```json", "").gsub("```", "")
      JSON.parse(json)
    elsif response_format_html?
      html = raw_response.strip.gsub("```html", "").chomp("```")
      clean_html_fragment(html)
    else
      raw_response.strip
    end
  end

  def clean_html_fragment(html)
    fragment = Nokogiri::HTML.fragment(html)

    fragment.traverse do |node|
      if node.text? && node.text.strip.empty?
        node.remove
      end
    end

    ActionController::Base.helpers.sanitize(fragment.to_html).strip
  end
end
