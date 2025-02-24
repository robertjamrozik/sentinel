# frozen_string_literal: true

module Raif
  module Adapters
    class Base
      include ActiveModel::Model

      attr_accessor :client, :model_api_name

      def chat(messages:, system_prompt: nil)
        raise NotImplementedError, "#{self.class.name} must implement a chat method"
      end
    end
  end
end
