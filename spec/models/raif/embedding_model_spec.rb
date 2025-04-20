# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::EmbeddingModel, type: :model do
  it "generates test embeddings" do
    model = Raif.embedding_model(:sentinel_test_embedding_model)
    embedding = model.generate_embedding!("Hello, world!")
    expect(embedding).to be_a(Array)
    expect(embedding.size).to eq(1536)
  end

  it "defaults to sentinel_test_embedding_model in test environment" do
    expect(Raif.default_embedding_model_key).to eq(:sentinel_test_embedding_model)
  end

  it "has model names for all built in embedding models" do
    Raif.default_embedding_models.values.flatten.each do |embedding_model_config|
      embedding_model = Raif.embedding_model(embedding_model_config[:key])
      expect(embedding_model.name).to_not include("Translation missing")
    end
  end
end
