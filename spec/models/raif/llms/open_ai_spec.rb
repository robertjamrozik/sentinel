# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::OpenAi, type: :model do
  it_behaves_like "an LLM that uses OpenAI's message formatting"

  let(:llm){ Raif.llm(:open_ai_gpt_4o) }
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
          "choices" => [
            {
              "message" => {
                "content" => "Response content"
              }
            }
          ],
          "usage" => {
            "completion_tokens" => 10,
            "prompt_tokens" => 5,
            "total_tokens" => 15
          }
        }
      end

      before do
        stubs.post("chat/completions") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
      end

      it "makes a request to the OpenAI API and processes the response" do
        model_completion = llm.chat(messages: [{ role: "user", content: "Hello" }], system_prompt: "You are a helpful assistant")

        expect(model_completion.raw_response).to eq("Response content")
        expect(model_completion.completion_tokens).to eq(10)
        expect(model_completion.prompt_tokens).to eq(5)
        expect(model_completion.total_tokens).to eq(15)
        expect(model_completion).to be_persisted
        expect(model_completion.messages).to eq([{ "role" => "user", "content" => [{ "text" => "Hello", "type" => "text" }] }])
        expect(model_completion.system_prompt).to eq("You are a helpful assistant")
        expect(model_completion.temperature).to eq(0.7)
        expect(model_completion.max_completion_tokens).to eq(nil)
        expect(model_completion.response_format).to eq("text")
        expect(model_completion.source).to be_nil
        expect(model_completion.llm_model_key).to eq("open_ai_gpt_4o")
        expect(model_completion.model_api_name).to eq("gpt-4o")
        expect(model_completion.response_format_parameter).to be_nil
      end
    end

    context "when the response format is json" do
      let(:response_body) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "{\n  \"joke\": \"Why don't scientists trust atoms? Because they make up everything!\"\n}"
              }
            }
          ],
          "usage" => {
            "completion_tokens" => 10,
            "prompt_tokens" => 15,
            "total_tokens" => 25
          }
        }
      end

      before do
        stubs.post("chat/completions") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
      end

      it "makes a request to the OpenAI API and processes the response" do
        messages = [
          { role: "user", content: "Hello" },
          { role: "assistant", content: "Hello! How can I assist you today?" },
          { role: "user", content: "Can you you tell me a joke?" },
        ]

        system_prompt = "You are a helpful assistant who specializes in telling jokes. Your response should be a properly formatted JSON object containing a single `joke` key. Do not include any other text in your response outside the JSON object." # rubocop:disable Layout/LineLength

        model_completion = llm.chat(messages: messages, response_format: :json, system_prompt: system_prompt)

        expect(model_completion.raw_response).to eq("{\n  \"joke\": \"Why don't scientists trust atoms? Because they make up everything!\"\n}")
        expect(model_completion.parsed_response).to eq({ "joke" => "Why don't scientists trust atoms? Because they make up everything!" })
        expect(model_completion.completion_tokens).to eq(10)
        expect(model_completion.prompt_tokens).to eq(15)
        expect(model_completion.total_tokens).to eq(25)
        expect(model_completion).to be_persisted
        expect(model_completion.messages).to eq([
          { "role" => "user", "content" => [{ "text" => "Hello", "type" => "text" }] },
          { "role" => "assistant", "content" => [{ "text" => "Hello! How can I assist you today?", "type" => "text" }] },
          { "role" => "user", "content" => [{ "text" => "Can you you tell me a joke?", "type" => "text" }] }
        ])
        expect(model_completion.system_prompt).to eq(system_prompt)
        expect(model_completion.temperature).to eq(0.7)
        expect(model_completion.max_completion_tokens).to eq(nil)
        expect(model_completion.response_format).to eq("json")
        expect(model_completion.source).to be_nil
        expect(model_completion.llm_model_key).to eq("open_ai_gpt_4o")
        expect(model_completion.model_api_name).to eq("gpt-4o")
        expect(model_completion.response_format_parameter).to eq("json_object")
      end
    end

    context "when the API returns a 400-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "error": {
              "message": "API rate limit exceeded",
              "type": "rate_limit_error",
              "param": null,
              "code": null
            }
          }
        JSON
      end

      before do
        stubs.post("chat/completions") do |_env|
          raise Faraday::ClientError.new(
            "Rate limited",
            { status: 429, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ClientError with the error message" do
        expect do
          llm.chat(messages: [{ role: "user", content: "Hello" }])
        end.to raise_error(Faraday::ClientError)
      end
    end

    context "when the API returns a 500-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "error": {
              "message": "Internal server error",
              "type": "server_error",
              "param": null,
              "code": null
            }
          }
        JSON
      end

      before do
        stubs.post("chat/completions") do |_env|
          raise Faraday::ServerError.new(
            "Internal server error",
            { status: 500, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ServerError with the error message" do
        expect do
          llm.chat(messages: [{ role: "user", content: "Hello" }])
        end.to raise_error(Faraday::ServerError, "Internal server error")
      end
    end
  end

  describe "#validate_json_schema!" do
    it "requires all objects to have additionalProperties set to false" do
      schema = {
        type: "object",
        properties: {
          foo: { type: "string" }
        }
      }
      expect { llm.validate_json_schema!(schema) }.to raise_error(Raif::Errors::OpenAi::JsonSchemaError)
    end

    it "requires top level type to be object" do
      schema = {
        type: "array",
        items: { type: "string" }
      }
      expect { llm.validate_json_schema!(schema) }.to raise_error(Raif::Errors::OpenAi::JsonSchemaError)
    end

    it "requires that all fields must be required" do
      schema = {
        type: "object",
        additionalProperties: false,
        properties: {
          foo: { type: "string" }
        }
      }
      expect { llm.validate_json_schema!(schema) }.to raise_error(Raif::Errors::OpenAi::JsonSchemaError)
    end

    it "returns true for a valid schema" do
      schema = {
        type: "object",
        additionalProperties: false,
        required: ["foo"],
        properties: {
          foo: { type: "string" }
        }
      }
      expect(llm.validate_json_schema!(schema)).to eq(true)
    end
  end

  describe "#build_request_parameters" do
    let(:parameters) { llm.send(:build_request_parameters, model_completion) }

    context "for text response format" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.8,
          response_format: "text",
          system_prompt: system_prompt
        )
      end

      context "with system prompt" do
        let(:system_prompt) { "You are a helpful assistant" }

        it "includes system prompt in the parameters" do
          expect(parameters[:model]).to eq("gpt-4o")
          expect(parameters[:temperature]).to eq(0.8)
          expect(parameters[:messages]).to contain_exactly(
            { "role" => "system", "content" => "You are a helpful assistant" },
            { "role" => "user", "content" => "Hello" }
          )
          expect(parameters[:response_format]).to be_nil
        end
      end

      context "without system prompt" do
        let(:system_prompt) { nil }

        it "builds parameters without system prompt" do
          expect(parameters[:model]).to eq("gpt-4o")
          expect(parameters[:temperature]).to eq(0.8)
          expect(parameters[:messages]).to eq([{ "role" => "user", "content" => "Hello" }])
          expect(parameters[:response_format]).to be_nil
        end
      end
    end

    context "for JSON response format" do
      let(:system_prompt) { "You are a helpful assistant" }
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          system_prompt: system_prompt,
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.5,
          response_format: "json"
        )
      end

      context "with existing system prompt" do
        it "appends 'Return your response as json.' to the system prompt" do
          message = parameters[:messages].first
          expect(message["role"]).to eq("system")
          expect(message["content"]).to eq("You are a helpful assistant. Return your response as JSON.")
        end
      end

      context "with no existing system prompt" do
        let(:system_prompt) { nil }

        it "Sets the system prompt to 'Return your response as JSON.'" do
          message = parameters[:messages].first
          expect(message["role"]).to eq("system")
          expect(message["content"]).to eq("Return your response as JSON.")
        end
      end

      context "when the model completion has a json_response_schema" do
        before do
          model_completion.source = Raif::TestJsonTask.new
        end

        it "sets the response_format to json_schema" do
          expect(parameters[:response_format]).to eq({
            type: "json_schema",
            json_schema: {
              name: "json_response_schema",
              strict: true,
              schema: {
                type: "object",
                additionalProperties: false,
                required: ["joke", "answer"],
                properties: {
                  joke: { type: "string" },
                  answer: { type: "string" }
                }
              }
            }
          })
        end
      end

      context "when the model completion does not have a json_response_schema" do
        it "sets the response_format to json_object" do
          expect(model_completion.json_response_schema).to be_nil
          expect(parameters[:response_format]).to eq({ type: "json_object" })
        end
      end
    end
  end

  describe "#determine_response_format" do
    context "with text response format" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "text",
          llm_model_key: "open_ai_gpt_4o"
        )
      end

      it "returns nil" do
        expect(llm.send(:determine_response_format, model_completion)).to be_nil
      end
    end

    context "with json response format but no json_response_schema" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o"
        )
      end

      it "returns the default json_schema format" do
        expect(model_completion.json_response_schema).to eq(nil)
        expect(llm.send(:determine_response_format, model_completion)).to eq({ type: "json_object" })
      end
    end

    context "with json response format and a model that doesn't support structured outputs" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_gpt_3_5_turbo",
          model_api_name: "gpt-3.5-turbo"
        )
      end

      it "returns json_object type when structured outputs are not supported" do
        llm = Raif.llm(:open_ai_gpt_3_5_turbo)
        result = llm.send(:determine_response_format, model_completion)
        expect(result).to eq({ type: "json_object" })
      end
    end

    context "with json format and source with json_response_schema" do
      let(:schema) do
        {
          type: "object",
          additionalProperties: false,
          required: ["result"],
          properties: {
            result: { type: "string" }
          }
        }
      end

      let(:source) do
        double("Source").tap do |s|
          allow(s).to receive(:respond_to?).with(:json_response_schema).and_return(true)
          allow(s).to receive(:json_response_schema).and_return(schema)
        end
      end

      let(:model_completion) do
        mc = Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o"
        )
        allow(mc).to receive(:source).and_return(source)
        mc
      end

      it "returns json_schema format with schema" do
        result = llm.send(:determine_response_format, model_completion)
        expect(result).to eq({
          type: "json_schema",
          json_schema: {
            name: "json_response_schema",
            strict: true,
            schema: schema
          }
        })
      end
    end
  end
end
