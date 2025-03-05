# frozen_string_literal: true

module Raif
  module Rspec
    module LlmStubbing

      def stub_sentinel_completion(completion_class, &block)
        allow_any_instance_of(Raif::Llm).to receive(:chat) do |_instance, args|
          {
            response: block.call(args[:messages]),
            prompt_tokens: rand(1..4),
            completion_tokens: rand(10..30)
          }
        end
      end

    end
  end
end
