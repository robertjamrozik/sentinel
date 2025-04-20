# frozen_string_literal: true

class Raif::EmbeddingModel
  include ActiveModel::Model

  attr_accessor :key,
    :api_name,
    :input_token_cost,
    :default_output_vector_size

  validates :default_output_vector_size, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :api_name, presence: true
  validates :key, presence: true

  def name
    I18n.t("sentinel.embedding_model_names.#{key}")
  end

  def generate_embedding!(input, dimensions: nil)
    raise NotImplementedError, "#{self.class.name} must implement #generate_embedding!"
  end
end
