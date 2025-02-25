# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Conversation, type: :model do
  let(:creator) { Raif::TestUser.create!(email: "test@example.com") }

  describe "#llm_messages" do
    it "returns the messages" do
      conversation = FB.create(:sentinel_conversation, :with_entries, creator: creator)
      expect(conversation.entries.count).to eq(3)

      messages = conversation.entries.oldest_first.map do |entry|
        [
          { "role" => "user", "content" => entry.sentinel_completion.prompt },
          { "role" => "assistant", "content" => entry.sentinel_completion.response }
        ]
      end.flatten

      expect(conversation.llm_messages).to eq(messages)
      expect(messages.length).to eq(6)
    end
  end
end
