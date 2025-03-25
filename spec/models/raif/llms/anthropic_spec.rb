# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::Anthropic, type: :model do
  let(:llm){ Raif.llm(:anthropic_claude_3_opus) }

  describe "#chat" do
    it "makes a request to the Anthropic API and processes the text response" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 200, body: {
          content: [{ type: "text", text: "Response content" }],
          usage: { input_tokens: 5, output_tokens: 10 }
        }.to_json)

      model_completion = llm.chat(messages: [{ role: "user", content: "Hello" }], system_prompt: "You are a helpful assistant.")
      expect(model_completion.raw_response).to eq("Response content")
      expect(model_completion.completion_tokens).to eq(10)
      expect(model_completion.prompt_tokens).to eq(5)
      expect(model_completion.total_tokens).to eq(15)
      expect(model_completion.llm_model_key).to eq("anthropic_claude_3_opus")
      expect(model_completion.model_api_name).to eq("claude-3-opus-latest")
      expect(model_completion.response_format).to eq("text")
      expect(model_completion.temperature).to eq(0.7)
      expect(model_completion.system_prompt).to eq("You are a helpful assistant.")
    end

    context "when the response format is JSON" do
      it "makes a request to the Anthropic API and processes the JSON response" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(status: 200, body: {
            content: [{ type: "text", text: "{\"name\": \"John\", \"age\": 30}" }],
            usage: { input_tokens: 5, output_tokens: 10 }
          }.to_json)

        model_completion = llm.chat(
          messages: [{ role: "user", content: "Hello" }],
          system_prompt: "You are a helpful assistant.",
          response_format: :json
        )
        expect(model_completion.raw_response).to eq("{\"name\": \"John\", \"age\": 30}")
        expect(model_completion.completion_tokens).to eq(10)
        expect(model_completion.prompt_tokens).to eq(5)
        expect(model_completion.total_tokens).to eq(15)
        expect(model_completion.llm_model_key).to eq("anthropic_claude_3_opus")
        expect(model_completion.model_api_name).to eq("claude-3-opus-latest")
        expect(model_completion.response_format).to eq("json")
      end
    end
  end
end
