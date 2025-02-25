# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Completions::ConversationEntry, type: :model do
  let(:creator) { Raif::TestUser.create!(email: "test@example.com") }
  let(:conversation) { FB.create(:sentinel_test_conversation, creator: creator) }
  let!(:entry) do
    FB.create(
      :sentinel_conversation_entry,
      sentinel_conversation: conversation,
      creator: creator,
      user_message: "Do some iteration",
      model_response_message: nil
    )
  end

  it "runs the completion" do
    stub_sentinel_completion(Raif::Completions::ConversationEntry){|_messages| llm_response.strip }

    result = nil
    expect do
      result = Raif::Completions::ConversationEntry.run(
        creator: conversation.creator,
        sentinel_conversation_entry: entry,
        available_model_tools: conversation.available_model_tools
      )
    end.to change{ Raif::Completion.count }.by(1)

    expect(result).to eq({
      "message" => "I think we should add these scenarios",
      "tools" => [
        {
          "name" => "test_model_tool",
          "arguments" => [
            { "title" => "Scenario 1", "description" => "A short description of scenario 1" },
            { "title" => "Scenario 2", "description" => "A short description of scenario 2" }
          ]
        }
      ]
    })

    completion = Raif::Completion.last
    expect(completion.llm_model_name).to eq("open_ai_gpt_4o")
    expect(completion.sentinel_conversation_entry).to eq(entry)
    expect(completion.type).to eq("Raif::Completions::ConversationEntry")
    expect(completion.prompt).to eq("Do some iteration")
    expect(completion.response_format).to eq("json")
    expect(completion.model_tool_invocations.count).to eq(1)

    expect(completion.response).to eq(llm_response)
    expect(completion.prompt_tokens).to be_present
    expect(completion.completion_tokens).to be_present
    expect(completion.total_tokens).to be_present
    expect(completion.creator).to eq(creator)
    expect(completion.system_prompt.strip).to eq(system_prompt.strip)
    expect(completion.requested_language_key).to eq(nil)
    expect(completion.response_format).to eq("json")

    mti = completion.model_tool_invocations.last
    expect(mti.tool_type).to eq("Raif::TestModelTool")
    expect(mti.tool_arguments).to eq([
      { "title" => "Scenario 1", "description" => "A short description of scenario 1" },
      { "title" => "Scenario 2", "description" => "A short description of scenario 2" }
    ])
  end

  let(:llm_response) do
    resp = <<~RESPONSE
      {
        "message": "I think we should add these scenarios",
        "tools": [
          {
            "name": "test_model_tool",
            "arguments": [
              {
                "title": "Scenario 1",
                "description": "A short description of scenario 1"
              },
              {
                "title": "Scenario 2",
                "description": "A short description of scenario 2"
              }
            ]
          }
        ]
      }
    RESPONSE

    resp.strip
  end

  let(:system_prompt) do
    <<~PROMPT.strip
      You are a friendly assistant.

      Your response should be a JSON object with the following format:
      { "message": "Your message to be displayed to the user" }
    PROMPT
  end
end
