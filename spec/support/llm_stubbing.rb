# frozen_string_literal: true

module Raif::LlmStubbing

  def stub_sentinel_completion(completion_class, &block)
    test_client = Raif::LlmClient.new(model_name: Raif.available_models.sample)
    adapter = Raif::Adapters::Test.new
    adapter.chat_handler = block
    test_client.adapter = adapter
    allow_any_instance_of(completion_class).to receive(:llm_client).and_return(test_client)
  end

end
