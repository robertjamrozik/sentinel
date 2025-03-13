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
        resp = <<~JSON.strip
          {
            "message" : "Hello",
            "tool" : {
              "name": "wikipedia_search",
              "arguments": { "query": "Paris" }
            }
          }
        JSON
        allow(conversation).to receive(:prompt_model_for_entry_response).and_return(Raif::ModelResponse.new(raw_response: resp))
      end

      it "processes the entry" do
        entry.process_entry!
        expect(entry.reload).to be_completed
        expect(entry.model_response_message).to eq("Hello")
        expect(entry.sentinel_model_tool_invocations.count).to eq(1)
        expect(entry.sentinel_model_tool_invocations.first.tool_name).to eq("wikipedia_search")
        expect(entry.sentinel_model_tool_invocations.first.tool_arguments).to eq("query" => "Paris")
      end
    end

    context "when the response does not include a tool call" do
      before do
        resp = <<~JSON.strip
          {
            "message" : "Hello"
          }
        JSON

        allow(conversation).to receive(:prompt_model_for_entry_response).and_return(Raif::ModelResponse.new(raw_response: resp))
      end

      it "processes the entry" do
        entry.process_entry!
        expect(entry.reload).to be_completed
        expect(entry.model_response_message).to eq("Hello")
        expect(entry.sentinel_model_tool_invocations.count).to eq(0)
      end
    end

    context "when the response contains malformed JSON" do
      before do
        resp = "This is not valid JSON"
        allow(conversation).to receive(:prompt_model_for_entry_response).and_return(Raif::ModelResponse.new(raw_response: resp))
      end

      it "marks the entry as failed" do
        entry.process_entry!
        expect(entry.reload).to be_failed
        expect(entry.model_response_message).to be_nil
        expect(entry.sentinel_model_tool_invocations.count).to eq(0)
      end
    end

    context "when the response is empty" do
      before do
        allow(conversation).to receive(:prompt_model_for_entry_response).and_return(Raif::ModelResponse.new(raw_response: nil))
      end

      it "marks the entry as failed" do
        entry.process_entry!
        expect(entry.reload).to be_failed
        expect(entry.model_response_message).to be_nil
        expect(entry.sentinel_model_tool_invocations.count).to eq(0)
      end
    end
  end
end
