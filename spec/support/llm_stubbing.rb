# frozen_string_literal: true

module Raif::LlmStubbing

  def stub_llm_completion(completion_class, &block)
    test_client = Llm::Client.new(model_name: Llm::Completion.llm_model_names.keys.sample)
    adapter = Llm::Adapters::Test.new
    adapter.chat_handler = block
    test_client.adapter = adapter
    allow_any_instance_of(completion_class).to receive(:llm_client).and_return(test_client)
  end

end
