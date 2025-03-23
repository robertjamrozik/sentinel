# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::OpenAi, type: :model do
  let(:llm){ Raif.llm(:open_ai_gpt_4o) }
  let(:mock_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
  end

  describe "#chat" do
    let(:model_completion) do
      Raif::ModelCompletion.new(
        messages: [{ role: "user", content: "Hello" }],
        llm_model_key: "open_ai_gpt_4o",
        model_api_name: "gpt-4o",
        response_format: "text"
      )
    end

    let(:response) do
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
      allow(mock_client).to receive(:chat).and_return(response)
    end

    it "makes a request to the OpenAI API and processes the response" do
      model_completion = llm.chat(messages: [{ role: "user", content: "Hello" }], system_prompt: "You are a helpful assistant")

      expect(model_completion.raw_response).to eq("Response content")
      expect(model_completion.completion_tokens).to eq(10)
      expect(model_completion.prompt_tokens).to eq(5)
      expect(model_completion.total_tokens).to eq(15)
      expect(model_completion).to be_persisted
      expect(model_completion.messages).to eq([{ "role" => "user", "content" => "Hello" }])
      expect(model_completion.system_prompt).to eq("You are a helpful assistant")
      expect(model_completion.temperature).to eq(0.7)
      expect(model_completion.max_completion_tokens).to eq(nil)
      expect(model_completion.response_format).to eq("text")
      expect(model_completion.source).to be_nil
      expect(model_completion.llm_model_key).to eq("open_ai_gpt_4o")
      expect(model_completion.model_api_name).to eq("gpt-4o")
    end
  end

  describe "#build_chat_parameters" do
    let(:parameters) { llm.send(:build_chat_parameters, model_completion) }

    context "with system prompt" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          system_prompt: "You are a helpful assistant",
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.5,
          response_format: "text"
        )
      end

      it "includes system prompt in the parameters" do
        expect(parameters[:model]).to eq("gpt-4o")
        expect(parameters[:temperature]).to eq(0.5)
        expect(parameters[:messages]).to contain_exactly(
          { "role" => "system", "content" => "You are a helpful assistant" },
          { "role" => "user", "content" => "Hello" }
        )
        expect(parameters[:response_format]).to be_nil
      end
    end

    context "with system prompt and JSON response format" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          system_prompt: "You are a helpful assistant",
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.5,
          response_format: "json"
        )
      end

      it "appends 'Return your response as json.' to the system prompt" do
        expect(parameters[:messages].first["content"]).to eq(
          "You are a helpful assistant. Return your response as JSON."
        )
      end
    end

    context "without system prompt" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          llm_model_key: "open_ai_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.8,
          response_format: "text"
        )
      end

      it "builds parameters without system prompt" do
        expect(parameters[:model]).to eq("gpt-4o")
        expect(parameters[:temperature]).to eq(0.8)
        expect(parameters[:messages]).to eq([{ "role" => "user", "content" => "Hello" }])
        expect(parameters[:response_format]).to be_nil
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
        expect(llm.send(:determine_response_format, model_completion)).to eq({
          "type" => "json_object"
        })
      end
    end

    context "with json format and source with json_response_schema" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => { "result" => { "type" => "string" } }
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
          "type" => "json_schema",
          "json_schema" => {
            name: "json_response",
            schema: schema,
            strict: true
          }
        })
      end
    end

    context "with json response format and supports_structured_outputs? returning false" do
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

        expect(result).to eq({ "type" => "json_object" })
      end
    end
  end
end
