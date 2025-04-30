# frozen_string_literal: true

module Raif::Concerns::LlmResponseParsing
  extend ActiveSupport::Concern

  included do
    normalizes :raw_response, with: ->(text){ text&.strip }

    enum :response_format, Raif::Llm.valid_response_formats, prefix: true

    validates :response_format, presence: true, inclusion: { in: response_formats.keys }

    class_attribute :allowed_tags
    class_attribute :allowed_attributes
  end

  class_methods do
    def llm_response_format(format)
      raise ArgumentError, "response_format must be one of: #{response_formats.keys.join(", ")}" unless response_formats.keys.include?(format.to_s)

      after_initialize -> { self.response_format = format }, if: :new_record?
    end

    def llm_response_allowed_tags(tags)
      self.allowed_tags = tags
    end

    def llm_response_allowed_attributes(attributes)
      self.allowed_attributes = attributes
    end
  end

  # Parses the response from the LLM into a structured format, based on the response_format.
  # If the response format is JSON, it will be parsed using JSON.parse.
  # If the response format is HTML, it will be sanitized via ActionController::Base.helpers.sanitize.
  #
  # @return [Object] The parsed response.
  def parsed_response
    return if raw_response.blank?

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

    allowed_tags = self.class.allowed_tags || Rails::HTML5::SafeListSanitizer.allowed_tags
    allowed_attributes = self.class.allowed_attributes || Rails::HTML5::SafeListSanitizer.allowed_attributes

    ActionController::Base.helpers.sanitize(fragment.to_html, tags: allowed_tags, attributes: allowed_attributes).strip
  end
end
