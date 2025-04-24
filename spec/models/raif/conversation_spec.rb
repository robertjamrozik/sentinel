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
          { "role" => "user", "content" => entry.user_message },
          { "role" => "assistant", "content" => entry.model_response_message }
        ]
      end.flatten

      expect(conversation.llm_messages).to eq(messages)
      expect(messages.length).to eq(6)
    end

    it "includes tool invocations" do
      conversation = FB.create(:sentinel_conversation, creator: creator)
      entry1 = FB.create(:sentinel_conversation_entry, :completed, sentinel_conversation: conversation, creator: creator)
      entry2 = FB.create(:sentinel_conversation_entry, :completed, :with_tool_invocation, sentinel_conversation: conversation, creator: creator)
      entry2.update_columns model_response_message: nil
      entry2.sentinel_model_tool_invocations.first.update!(result: { "status": "success" })
      entry3 = FB.create(:sentinel_conversation_entry, :completed, :with_tool_invocation, sentinel_conversation: conversation, creator: creator)

      mti = entry2.sentinel_model_tool_invocations.first
      mti2 = entry3.sentinel_model_tool_invocations.first
      allow(mti2).to receive(:result_llm_message).and_return(nil)

      messages = [
        { "role" => "user", "content" => entry1.user_message },
        { "role" => "assistant", "content" => entry1.model_response_message },
        { "role" => "user", "content" => entry2.user_message },
        { "role" => "assistant", "content" => "Invoking tool: #{mti.tool_name} with arguments: #{mti.tool_arguments.to_json}" },
        { "role" => "assistant", "content" => "Mock Observation for #{mti.id}. Result was: success" },
        { "role" => "user", "content" => entry3.user_message },
        { "role" => "assistant", "content" => entry3.model_response_message },
        { "role" => "assistant", "content" => "Invoking tool: #{mti2.tool_name} with arguments: #{mti2.tool_arguments.to_json}" }
      ]

      expect(conversation.llm_messages).to eq(messages)
    end
  end

  it "does not allow invalid types" do
    conversation = FB.build(:sentinel_conversation, type: "InvalidType", creator: creator)
    expect(conversation).not_to be_valid
    expect(conversation.errors.full_messages).to include("Type is not included in the list")
    conversation.type = "Raif::TestConversation"
    expect(conversation).to be_valid
  end

  describe "#system_prompt" do
    let(:conversation) { FB.build(:sentinel_conversation, creator: creator) }
    let(:test_conversation) { FB.build(:sentinel_test_conversation, creator: creator) }

    it "returns the system prompt" do
      prompt = <<~PROMPT.strip
        You are a helpful assistant who is collaborating with a teammate.
      PROMPT

      expect(conversation.build_system_prompt.strip).to eq(prompt)
    end

    it "includes language preference if specified" do
      conversation.requested_language_key = "es"
      expect(conversation.build_system_prompt.strip).to end_with("You're collaborating with teammate who speaks Spanish. Please respond in Spanish.")
    end
  end

  describe "#prompt_model_for_entry_response" do
    it "returns a model completion" do
      conversation = FB.create(:sentinel_conversation, :with_entries, entries_count: 1, creator: creator)

      stub_sentinel_conversation(conversation) do |_messages|
        "Hello user"
      end

      completion = conversation.prompt_model_for_entry_response(entry: conversation.entries.first)
      expect(completion).to be_a(Raif::ModelCompletion)
      expect(completion.raw_response).to eq("Hello user")
      expect(completion.response_format).to eq("text")
    end
  end

  describe "#process_model_response_message" do
    it "allows for conversation type-specific processing of the model response message" do
      conversation = FB.create(:sentinel_test_conversation, creator: creator)
      entry = FB.create(:sentinel_conversation_entry, sentinel_conversation: conversation, creator: creator)
      expect(conversation.process_model_response_message(message: "Hello jerk.", entry: entry)).to eq("Hello [REDACTED].")
    end
  end
end
