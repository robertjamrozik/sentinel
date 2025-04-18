# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::EmbeddingModels::OpenAi, type: :model do
  let(:model) { Raif.embedding_model(:open_ai_text_embedding_3_small) }
  let(:mock_connection) { instance_double(Faraday::Connection) }
  let(:mock_response) { instance_double(Faraday::Response) }

  before do
    allow(Faraday).to receive(:new).and_return(mock_connection)
    allow(model).to receive(:connection).and_return(mock_connection)
  end

  describe "initialization" do
    it "sets the correct attributes" do
      expect(model.key).to eq(:open_ai_text_embedding_3_small)
      expect(model.api_name).to eq("text-embedding-3-small")
      expect(model.input_token_cost).to eq(0.02 / 1_000_000)
    end
  end

  describe "#generate_embedding!" do
    context "with a string input" do
      let(:input) { "This is a test sentence" }
      let(:embedding_vector) { Array.new(1536) { rand(-1.0..1.0) } }
      let(:response_body) { { "data" => [{ "embedding" => embedding_vector }] } }

      before do
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:body).and_return(response_body)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
      end

      let(:mock_request) { double("Request") }
      before do
        allow(mock_request).to receive(:body=)
      end

      it "makes a request to the OpenAI API with the correct parameters" do
        expect(mock_connection).to receive(:post).with("embeddings")
        expect(mock_request).to receive(:body=).with({
          model: "text-embedding-3-small",
          input: input
        })

        result = model.generate_embedding!(input)
        expect(result).to eq(embedding_vector)
      end

      context "with dimensions parameter" do
        let(:dimensions) { 256 }

        it "includes the dimensions parameter in the request" do
          expect(mock_connection).to receive(:post).with("embeddings")
          expect(mock_request).to receive(:body=).with({
            model: "text-embedding-3-small",
            input: input,
            dimensions: dimensions
          })

          model.generate_embedding!(input, dimensions: dimensions)
        end
      end
    end

    context "with an array input" do
      let(:input) { ["This is sentence one", "This is sentence two"] }
      let(:embedding_vectors) do
        [
          Array.new(1536) { rand(-1.0..1.0) },
          Array.new(1536) { rand(-1.0..1.0) }
        ]
      end

      let(:response_body) { { "data" => [{ "embedding" => embedding_vectors[0] }, { "embedding" => embedding_vectors[1] }] } }

      before do
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:body).and_return(response_body)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
      end

      let(:mock_request) { double("Request") }
      before do
        allow(mock_request).to receive(:body=)
      end

      it "makes a request to the OpenAI API with the array input" do
        expect(mock_connection).to receive(:post).with("embeddings")
        expect(mock_request).to receive(:body=).with({
          model: "text-embedding-3-small",
          input: input
        })

        result = model.generate_embedding!(input)
        expect(result).to eq(embedding_vectors)
      end
    end

    context "with invalid input type" do
      it "raises an ArgumentError for numeric input" do
        expect { model.generate_embedding!(123) }.to raise_error(
          ArgumentError,
          "Raif::EmbeddingModels::OpenAi#generate_embedding! input must be a string or an array of strings"
        )
      end

      it "raises an ArgumentError for hash input" do
        expect { model.generate_embedding!({ text: "test" }) }.to raise_error(
          ArgumentError,
          "Raif::EmbeddingModels::OpenAi#generate_embedding! input must be a string or an array of strings"
        )
      end
    end

    context "when the API returns an error" do
      let(:input) { "Test input" }
      let(:error_response_body) { { "error" => { "message" => "API rate limit exceeded", "type" => "rate_limit_error" } } }
      let(:mock_request) { double("Request") }

      before do
        allow(mock_response).to receive(:success?).and_return(false)
        allow(mock_response).to receive(:status).and_return(429)
        allow(mock_response).to receive(:body).and_return(error_response_body)
        allow(mock_connection).to receive(:post).and_yield(mock_request).and_return(mock_response)
        allow(mock_request).to receive(:body=)
      end

      it "raises an ApiError with the error message" do
        expect do
          model.generate_embedding!(input)
        end.to raise_error(Raif::Errors::OpenAi::ApiError, "API rate limit exceeded")
      end

      context "when error message is missing" do
        let(:error_response_body) { {} }

        before do
          allow(mock_response).to receive(:status).and_return(500)
        end

        it "raises an ApiError with the status code" do
          expect do
            model.generate_embedding!(input)
          end.to raise_error(Raif::Errors::OpenAi::ApiError, "OpenAI API error: 500")
        end
      end
    end
  end
end
