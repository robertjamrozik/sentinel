# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Concerns::LlmResponseParsing do
  describe "llm_response_allowed_tags" do
    it "allows the specified tags" do
      expect(Raif::TestHtmlTask.allowed_tags).to eq(%w[p b i u s])
    end

    it "strips tags that are not allowed" do
      task = Raif::TestHtmlTask.new(raw_response: "<div>Why is a pirate's favorite letter 'R'?</div><p>Because, if you think about it, <b style=\"color:red;\">R</b> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength
      expect(task.parsed_response).to eq("Why is a pirate's favorite letter 'R'?<p>Because, if you think about it, <b style=\"color:red;\">R</b> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength
    end
  end

  describe "llm_response_allowed_attributes" do
    it "allows the specified attributes" do
      expect(Raif::TestHtmlTask.allowed_attributes).to eq(%w[style])
    end

    it "strips attributes that are not allowed" do
      task = Raif::TestHtmlTask.new(raw_response: "<p data-example='true'>Why is a pirate's favorite letter 'R'?</p><p>Because, if you think about it, <b style=\"color:red;\">R</b> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength
      expect(task.parsed_response).to eq("<p>Why is a pirate's favorite letter 'R'?</p><p>Because, if you think about it, <b style=\"color:red;\">R</b> is the only letter that makes sense.</p>") # rubocop:disable Layout/LineLength
    end
  end
end
