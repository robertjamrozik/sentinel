# frozen_string_literal: true

class Raif::ModelCompletion < Raif::ApplicationRecord
  belongs_to :source, polymorphic: true, optional: true

  enum :response_format, Raif::Llm.valid_response_formats, prefix: true

  validates :response_format, presence: true, inclusion: { in: response_formats.keys }
  validates :llm_model_key, presence: true, inclusion: { in: ->{ Raif.available_llm_keys.map(&:to_s) } }
  validates :model_api_name, presence: true
  validates :type, presence: true

  def prompt_model_for_response!
    raise NotImplementedError, "Raif::ModelCompletion subclasses must implement #prompt_model_for_response!"
  end

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

private

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
