# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation interface", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  fit "displays the conversation interface", js: true do
    stub_sentinel_conversation(Raif::Conversation) do |_messages|
      {
        message: "I'm great how are you?"
      }.to_json
    end

    visit chat_path
    expect(page).to have_content("Hello, how can I help you today?")

    fill_in "conversation_entry_user_message", with: "How are you today?"
    expect do
      click_button "Send"
    end.to have_enqueued_job(Raif::ConversationEntryJob)
      .and change(Raif::ConversationEntry, :count).by(1)

    perform_enqueued_jobs

    expect(page).to have_content("I'm great how are you?")

    conversation = Raif::Conversation.last
    expect(conversation.entries.count).to eq(1)

    entry = conversation.entries.last
    user = Raif::TestUser.last
    expect(entry.user_message).to eq("How are you today?")
    expect(entry.model_response_message).to eq("I'm great how are you?")
    expect(entry.raw_response).to eq("{\"message\":\"I'm great how are you?\"}")
    expect(entry).to be_completed
    expect(entry.creator).to eq(user)
    expect(entry.sentinel_user_tool_invocation).to be_nil
    expect(entry.sentinel_conversation).to eq(conversation)
    expect(entry.sentinel_model_completion).to be_present

    mc = entry.sentinel_model_completion
    expect(mc.model_api_name).to eq("sentinel-test-llm")
    expect(mc.llm_model_key).to eq("sentinel_test_llm")
    expect(mc.parsed_response).to eq({ "message" => "I'm great how are you?" })
  end
end
