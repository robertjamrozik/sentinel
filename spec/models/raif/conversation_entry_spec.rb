# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ConversationEntry, type: :model do
  it "increments the conversation's entry count" do
    conversation = FB.create(:sentinel_conversation)

    expect do
      conversation.entries.create!(creator: conversation.creator)
    end.to change { conversation.reload.conversation_entries_count }.by(1)
  end

  it "runs the completion" do
    raise "needs to be implemented"
  end
end
