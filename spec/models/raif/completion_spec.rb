# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ConversationEntry, type: :model do
  describe "#build_system_prompt" do
    it "returns the system prompt" do
      completion = FB.build(:sentinel_completion)
      expect(completion.build_system_prompt).to eq("You are a friendly assistant.")
    end

    it "returns the system prompt with the language preference" do
      completion = FB.build(:sentinel_completion, requested_language_key: "en")
      expect(completion.build_system_prompt).to eq("You are a friendly assistant. You're collaborating with teammate who speaks English. Please respond in English.") # rubocop:disable Layout/LineLength
    end
  end
end
