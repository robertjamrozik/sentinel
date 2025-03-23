# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::BedrockClaude, type: :model do
  let(:llm){ Raif.llm(:bedrock_claude_3_5_sonnet) }
  let(:client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }

  before do
    allow(llm).to receive(:bedrock_client).and_return(client)
    client.stub_responses(:converse, { output: bedrock_response })
  end

  describe "#chat" do
    let(:bedrock_response) { { output: "Response content" } }

    it "makes a request to the Anthropic API and processes the text response" do
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
  end
end
