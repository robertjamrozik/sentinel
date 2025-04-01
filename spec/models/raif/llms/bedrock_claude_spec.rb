# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::BedrockClaude, type: :model do
  let(:llm){ Raif.llm(:bedrock_claude_3_5_sonnet) }
  let(:client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
  let(:bedrock_response) { "Response content" }

  before do
    allow(llm).to receive(:bedrock_client).and_return(client)
    client.stub_responses(:converse, {
      output: {
        message: {
          role: "assistant",
          content: [{ text: bedrock_response }]
        }
      },
      stop_reason: "end_turn",
      usage: { input_tokens: 8, output_tokens: 13, total_tokens: 21 },
      metrics: { latency_ms: 540 }
    })
  end

  describe "#chat" do
    it "makes a request to the Anthropic API and processes the text response" do
      model_completion = llm.chat(messages: [{ role: "user", content: "Hello" }], system_prompt: "You are a helpful assistant.")
      expect(model_completion.raw_response).to eq("Response content")
      expect(model_completion.completion_tokens).to eq(13)
      expect(model_completion.prompt_tokens).to eq(8)
      expect(model_completion.total_tokens).to eq(21)
      expect(model_completion.llm_model_key).to eq("bedrock_claude_3_5_sonnet")
      expect(model_completion.model_api_name).to eq("us.anthropic.claude-3-5-sonnet-20241022-v2:0")
      expect(model_completion.response_format).to eq("text")
      expect(model_completion.temperature).to eq(0.7)
      expect(model_completion.system_prompt).to eq("You are a helpful assistant.")
    end
  end

  describe "#build_api_parameters" do
    let(:model_completion) do
      Raif::ModelCompletion.new(
        messages: [{ role: "user", content: "Hello" }],
        system_prompt: "You are a helpful assistant.",
        llm_model_key: "bedrock_claude_3_5_sonnet",
        model_api_name: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
      )
    end

    it "builds the correct parameters" do
      parameters = llm.send(:build_api_parameters, model_completion)
      expect(parameters[:model_id]).to eq("us.anthropic.claude-3-5-sonnet-20241022-v2:0")
      expect(parameters[:inference_config][:max_tokens]).to eq(8192)
      expect(parameters[:messages]).to eq([{ role: "user", content: [{ text: "Hello" }] }])
    end
  end
end
