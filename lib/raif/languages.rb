# frozen_string_literal: true

module Raif
  SUPPORTED_LANGUAGES = [
    "ar",
    "da",
    "de",
    "en",
    "es",
    "fi",
    "fr",
    "he",
    "hi",
    "it",
    "ja",
    "ko",
    "nl",
    "no",
    "pl",
    "pt",
    "ru",
    "sv",
    "th",
    "tr",
    "uk",
    "vi",
    "zh",
  ].freeze

  def self.supported_languages
    SUPPORTED_LANGUAGES
  end
end
