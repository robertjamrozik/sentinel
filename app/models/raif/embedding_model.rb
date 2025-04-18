# frozen_string_literal: true

class Raif::EmbeddingModel
  include ActiveModel::Model

  attr_accessor :key,
    :api_name,
    :input_token_cost

  def name
    I18n.t("sentinel.embedding_model_names.#{key}")
  end

  def generate_embedding!(input, dimensions: nil)
    raise NotImplementedError, "#{self.class.name} must implement #generate_embedding!"
  end
end
