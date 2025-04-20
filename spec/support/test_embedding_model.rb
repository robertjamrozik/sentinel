# frozen_string_literal: true

module Raif
  module EmbeddingModels
    class Test < Raif::EmbeddingModel
      attr_accessor :embedding_handler

      def generate_embedding!(input, dimensions: nil)
        if input.is_a?(Array)
          input.map { |text| generate_test_embedding!(text, dimensions:) }
        else
          generate_test_embedding!(input, dimensions:)
        end
      end

      def generate_test_embedding!(input, dimensions: nil)
        if embedding_handler.present?
          embedding_handler.call(input, dimensions)
        else
          dimensions ||= default_output_vector_size
          Array.new(dimensions) { rand(-1.0..1.0) }
        end
      end

    end
  end
end
