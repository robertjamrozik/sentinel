# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::Anthropic, type: :model do
  let(:llm){ Raif.llm(:anthropic_claude_3_opus) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new do |builder|
      builder.adapter :test, stubs
      builder.request :json
      builder.response :json
      builder.response :raise_error
    end
  end

  before do
    allow(llm).to receive(:connection).and_return(test_connection)
  end

  describe "#chat" do
    context "when the response format is text" do
      let(:response_body) do
        {
          "content" => [{ "type" => "text", "text" => "Response content" }],
          "usage" => { "input_tokens" => 5, "output_tokens" => 10 }
        }
      end

      before do
        stubs.post("messages") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
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
          "content" => [{ "type" => "text", "text" => "{\"name\": \"John\", \"age\": 30}" }],
          "usage" => { "input_tokens" => 5, "output_tokens" => 10 }
        }
      end

      before do
        stubs.post("messages") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
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
          "content" => [
            {
              "type" => "tool_use",
              "name" => "calculator",
              "input" => {
                "operation" => "add",
                "operands" => [5, 7]
              }
            }
          ],
          "usage" => { "input_tokens" => 8, "output_tokens" => 12 }
        }
      end

      before do
        stubs.post("messages") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
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

    context "when the API returns a 400-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "error": {
              "message": "API rate limit exceeded",
              "type": "rate_limit_error"
            }
          }
        JSON
      end

      before do
        stubs.post("messages") do |_env|
          raise Faraday::ClientError.new(
            "Rate limited",
            { status: 429, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ClientError with the error message" do
        expect do
          llm.chat(message: "Hello")
        end.to raise_error(Faraday::ClientError)
      end
    end

    context "when the API returns a 500-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "type": "error",
            "error": {
              "type": "server_error",
              "message": "Internal server error"
            }
          }
        JSON
      end

      before do
        stubs.post("messages") do |_env|
          raise Faraday::ServerError.new(
            "Internal server error",
            { status: 500, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ServerError with the error message" do
        expect do
          llm.chat(message: "Hello")
        end.to raise_error(Faraday::ServerError)
      end
    end
  end

  describe "#format_messages" do
    it "formats the messages correctly with a string as the content" do
      messages = [{ "role" => "user", "content" => "Hello" }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([{ "role" => "user", "content" => [{ "text" => "Hello", "type" => "text" }] }])
    end

    it "formats the messages correctly with an array as the content" do
      messages = [{ "role" => "user", "content" => ["Hello", "World"] }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            { "type" => "text", "text" => "Hello" },
            { "type" => "text", "text" => "World" }
          ]
        }
      ])
    end

    it "formats the messages correctly with an image" do
      image_path = Raif::Engine.root.join("spec/fixtures/files/cultivate.png")
      image = Raif::ModelImageInput.new(input: image_path)
      messages = [{
        "role" => "user",
        "content" => [
          { "text" => "Hello" },
          image
        ]
      }]

      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            { "text" => "Hello" },
            {
              "type" => "image",
              "source" => {
                "type" => "base64",
                "media_type" => "image/png",
                "data" => Base64.strict_encode64(File.read(image_path))
              }
            }
          ]
        }
      ])
    end

    it "formats the messages correctly when using image_url" do
      image_url = "https://example.com/image.png"
      image = Raif::ModelImageInput.new(url: image_url)
      messages = [{ "role" => "user", "content" => [image] }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            {
              "type" => "image",
              "source" => {
                "type" => "url",
                "url" => image_url
              }
            }
          ]
        }
      ])
    end

    it "formats the messages correctly with a file" do
      file_path = Raif::Engine.root.join("spec/fixtures/files/test.pdf")
      file = Raif::ModelFileInput.new(input: file_path)
      messages = [{
        "role" => "user",
        "content" => [
          "What's in this file?",
          file
        ]
      }]

      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            { "type" => "text", "text" => "What's in this file?" },
            {
              "type" => "document",
              "source" => {
                "type" => "base64",
                "media_type" => "application/pdf",
                "data" => Base64.strict_encode64(File.read(file_path))
              }
            }
          ]
        }
      ])
    end

    it "formats the messages correctly when using file_url" do
      file_url = "https://example.com/file.pdf"
      file = Raif::ModelFileInput.new(url: file_url)
      messages = [{ "role" => "user", "content" => [file] }]
      formatted_messages = llm.format_messages(messages)
      expect(formatted_messages).to eq([
        {
          "role" => "user",
          "content" => [
            {
              "type" => "document",
              "source" => {
                "type" => "url",
                "url" => file_url
              }
            }
          ]
        }
      ])
    end
  end
end
