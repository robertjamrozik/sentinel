# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::EmbeddingModel, type: :model do
  it "has model names for all built in embedding models" do
    Raif.default_embedding_models.values.flatten.each do |embedding_model_config|
      embedding_model = Raif.embedding_model(embedding_model_config[:key])
      expect(embedding_model.name).to_not include("Translation missing")
    end
  end
end
