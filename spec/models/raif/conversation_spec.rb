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

    it "includes language preference if specified" do
      conversation.requested_language_key = "es"
      expect(conversation.system_prompt.strip).to end_with("You're collaborating with teammate who speaks Spanish. Please respond in Spanish.")
    end

    context "when no tools are available" do
      it "does not include tool usage instructions" do
        prompt = <<~PROMPT.strip
          You are a helpful assistant who is collaborating with a teammate.

          # Your Responses
          Your responses should always be in JSON format with a "message" field containing your response to your collaborator. For example:
          {
            "message": "Your response message"
          }

          # Other rules/reminders
          - **Always** respond with a single, valid JSON object containing at minimum a "message" field, and optionally a "tool" field.
        PROMPT

        expect(conversation.system_prompt.strip).to eq(prompt)
      end
    end

    context "when tools are available" do
      it "includes tool usage instructions" do
        prompt = <<~PROMPT.strip
          You are a helpful assistant who is collaborating with a teammate.

          # Your Responses
          Your responses should always be in JSON format with a "message" field containing your response to your collaborator. For example:
          {
            "message": "Your response message"
          }

          # Available Tools
          You have access to the following tools:
          Name: test_model
          Description: Mock Tool Description
          Arguments Schema:
          {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "title": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                }
              },
              "required": [
                "title",
                "description"
              ]
            }
          }
          Example Usage:
          {
            "name": "test_tool",
            "arguments": [
              {
                "title": "foo",
                "description": "bar"
              }
            ]
          }

          ---
          Name: wikipedia_search
          Description: Search Wikipedia for information
          Arguments Schema:
          {
            "query": {
              "type": "string",
              "description": "The query to search Wikipedia for"
            }
          }
          Example Usage:
          {
            "name": "wikipedia_search",
            "arguments": {
              "query": "Jimmy Buffett"
            }
          }

          # Tool Usage
          To utilize a tool, include a tool object in your JSON response with the name of the tool you want to use and the arguments for that tool. An example response that invokes a tool:
          {
            "message": "I suggest we add a new scenario.",
            "tool": {
              "name": "tool_name",
              "arguments": {"arg_name": "Example arg"}
            }
          }

          # Other rules/reminders
          - Use tools if you think they are useful for the conversation.
          - **Always** respond with a single, valid JSON object containing at minimum a "message" field, and optionally a "tool" field.
        PROMPT

        expect(test_conversation.system_prompt.strip).to eq(prompt)
      end
    end
  end

  describe "#prompt_model_for_entry_response" do
    it "returns a model completion" do
      conversation = FB.create(:sentinel_conversation, :with_entries, entries_count: 1, creator: creator)

      stub_sentinel_conversation(conversation) do |_messages|
        <<~JSON.strip
          { "message" : "Hello" }
        JSON
      end

      completion = conversation.prompt_model_for_entry_response(entry: conversation.entries.first)
      expect(completion).to be_a(Raif::ModelCompletion)
      expect(completion.raw_response).to eq("{ \"message\" : \"Hello\" }")
      expect(completion.response_format).to eq(:json)
    end
  end
end
