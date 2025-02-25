# frozen_string_literal: true

module Raif
  module Rspec
    module LlmStubbing

      def stub_sentinel_completion(completion_class, &block)
        test_client = Raif::TestClient.new
        test_client.chat_handler = block
        allow_any_instance_of(completion_class).to receive(:llm_client).and_return(test_client)
      end

    end
  end
end
