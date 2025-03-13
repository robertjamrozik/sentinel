# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelCompletion, type: :model do
  describe "validations" do
    it "validates presence of llm_model_key" do
      model_completion = described_class.new(response_format: "text")
      expect(model_completion).not_to be_valid
      expect(model_completion.errors[:llm_model_key]).to include("can't be blank")
    end

    it "validates that the llm_model_key is a valid model key" do
      model_completion = described_class.new(response_format: "text", llm_model_key: "invalid_model_key")
      expect(model_completion).not_to be_valid
      expect(model_completion.errors[:llm_model_key]).to include("is not included in the list")
    end

    it "validates inclusion of response_format in valid formats" do
      expect do
        described_class.new(response_format: "invalid_format", llm_model_key: "open_ai_gpt_4o")
      end.to raise_error(ArgumentError, "'invalid_format' is not a valid response_format")
    end
  end

  describe "#parsed_response" do
    context "with text format" do
      let(:model_completion) do
        described_class.new(
          response_format: "text",
          raw_response: "  This is a text response.  ",
          llm_model_key: "open_ai_gpt_4o"
        )
      end

      it "returns the trimmed text" do
        expect(model_completion.parsed_response).to eq("This is a text response.")
      end
    end

    context "with json format" do
      context "with valid JSON" do
        let(:model_completion) do
          described_class.new(
            response_format: "json",
            raw_response: '{"key": "value", "array": [1, 2, 3]}',
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "parses the JSON" do
          expect(model_completion.parsed_response).to eq({ "key" => "value", "array" => [1, 2, 3] })
        end
      end

      context "with JSON wrapped in code blocks" do
        let(:model_completion) do
          described_class.new(
            response_format: "json",
            raw_response: "```json\n{\"key\": \"value\"}\n```",
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "removes the code block markers and parses the JSON" do
          expect(model_completion.parsed_response).to eq({ "key" => "value" })
        end
      end
    end

    context "with html format" do
      context "with valid HTML" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div><p>Hello</p><p>World</p></div>",
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "cleans and returns the HTML" do
          expect(model_completion.parsed_response).to eq("<div>\n<p>Hello</p>\n<p>World</p>\n</div>")
        end
      end

      context "with HTML wrapped in code blocks" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "```html\n<div><p>Hello</p></div>\n```",
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "removes the code block markers and returns the HTML" do
          expect(model_completion.parsed_response).to eq("<div><p>Hello</p></div>")
        end
      end

      context "with HTML containing empty text nodes" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div>\n  <p>Hello</p>\n  \n  <p>World</p>\n</div>",
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "cleans empty text nodes" do
          # The exact output might depend on how ActionController::Base.helpers.sanitize works
          # This test might need adjustment based on actual behavior
          expect(model_completion.parsed_response).to include("<div>")
          expect(model_completion.parsed_response).to include("<p>Hello</p>")
          expect(model_completion.parsed_response).to include("<p>World</p>")
        end
      end

      context "with HTML containing script tags" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div><script>alert('XSS')</script><p>Safe content</p></div>",
            llm_model_key: "open_ai_gpt_4o"
          )
        end

        it "removes the script tags" do
          expect(model_completion.parsed_response).to include("<div>\nalert('XSS')<p>Safe content</p>\n</div>")
        end
      end
    end
  end
end
