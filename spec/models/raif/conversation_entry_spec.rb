# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ConversationEntry, type: :model do
  let(:creator) { Raif::TestUser.create!(email: "test@example.com") }

  it "increments the conversation's entry count" do
    conversation = FB.create(:sentinel_conversation, creator: creator)

    expect do
      conversation.entries.create!(creator: conversation.creator)
    end.to change { conversation.reload.conversation_entries_count }.by(1)
  end

  describe "#process_entry!" do
    let(:conversation) { FB.create(:sentinel_test_conversation, creator: creator) }
    let(:entry) { FB.create(:sentinel_conversation_entry, sentinel_conversation: conversation, creator: creator) }

    context "when the response includes a tool call" do
      before do
        tool_calls = [{
          "name": "test_model_tool",
          "arguments": { "items": [{ "title": "foo", "description": "bar" }] }
        }]

        stub_sentinel_conversation(conversation, response_tool_calls: tool_calls) do |_messages|
          "Hello"
        end
      end

      it "processes the entry" do
        entry.process_entry!
        expect(entry.reload).to be_completed
        expect(entry.model_response_message).to eq("Hello")
        expect(entry.sentinel_model_tool_invocations.count).to eq(1)
        expect(entry.sentinel_model_tool_invocations.first.tool_name).to eq("test_model_tool")
        expect(entry.sentinel_model_tool_invocations.first.tool_arguments).to eq({ "items" => [{ "title" => "foo", "description" => "bar" }] })
      end
    end

    context "when the response does not include a tool call" do
      before do
        stub_sentinel_conversation(conversation) do |_messages|
          "Hello user"
        end
      end

      it "processes the entry" do
        entry.process_entry!
        expect(entry.reload).to be_completed
        expect(entry.model_response_message).to eq("Hello user")
        expect(entry.sentinel_model_tool_invocations.count).to eq(0)
      end
    end
  end
end
