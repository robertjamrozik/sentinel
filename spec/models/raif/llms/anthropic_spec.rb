# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::Anthropic, type: :model do
  let(:llm){ Raif.llm(:anthropic_claude_3_opus) }
  let(:mock_connection) { instance_double(Faraday::Connection) }
  let(:mock_response) { instance_double(Faraday::Response) }

  before do
    allow(Faraday).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:post).and_return(mock_response)
    allow(mock_response).to receive(:success?).and_return(true)
  end

  describe "#chat" do
    context "when the response format is text" do
      let(:response_body) do
        {
          content: [{ type: "text", text: "Response content" }],
          usage: { input_tokens: 5, output_tokens: 10 }
        }
      end

      let(:mock_request) { double("Request") }

      before do
        allow(mock_response).to receive(:body).and_return(response_body.to_json)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
        allow(mock_request).to receive(:body=)
      end

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

    context "when the response format is JSON" do
      let(:response_body) do
        {
          content: [{ type: "text", text: "{\"name\": \"John\", \"age\": 30}" }],
          usage: { input_tokens: 5, output_tokens: 10 }
        }
      end

      let(:mock_request) { double("Request") }

      before do
        allow(mock_response).to receive(:body).and_return(response_body.to_json)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
        allow(mock_request).to receive(:body=)
      end

      it "makes a request to the Anthropic API and processes the JSON response" do
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

    context "when the response includes tool use" do
      let(:response_body) do
        {
          content: [
            {
              type: "tool_use",
              name: "calculator",
              input: {
                "operation": "add",
                "operands": [5, 7]
              }
            }
          ],
          usage: { input_tokens: 8, output_tokens: 12 }
        }
      end

      let(:mock_request) { double("Request") }

      before do
        allow(mock_response).to receive(:body).and_return(response_body.to_json)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
        allow(mock_request).to receive(:body=)
      end

      it "extracts tool calls correctly" do
        model_completion = llm.chat(
          messages: [{ role: "user", content: "Add 5 + 7" }],
          system_prompt: "You can use tools."
        )

        expect(model_completion.response_tool_calls).to eq([
          {
            "name" => "calculator",
            "arguments" => { "operation" => "add", "operands" => [5, 7] }
          }
        ])
      end
    end

    context "when the API returns an error" do
      let(:error_response_body) do
        {
          error: {
            message: "API rate limit exceeded",
            type: "rate_limit_error"
          }
        }
      end

      let(:mock_request) { double("Request") }

      before do
        allow(mock_response).to receive(:success?).and_return(false)
        allow(mock_response).to receive(:status).and_return(429)
        allow(mock_response).to receive(:body).and_return(error_response_body.to_json)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
        allow(mock_request).to receive(:body=)
      end

      it "raises an ApiError with the error message" do
        expect do
          llm.chat(message: "Hello")
        end.to raise_error(Raif::Errors::Anthropic::ApiError, "API rate limit exceeded")
      end
    end
  end
end
