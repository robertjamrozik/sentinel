# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Completion, type: :model do
  describe "#build_system_prompt" do
    it "returns the system prompt with no language preference" do
      completion = FB.build(:sentinel_completion)
      expect(completion.requested_language_key).to be_nil
      expect(completion.build_system_prompt).to eq("You are a friendly assistant.")
    end

    it "returns the system prompt with the language preference" do
      completion = FB.build(:sentinel_completion, requested_language_key: "en")
      expect(completion.build_system_prompt).to eq("You are a friendly assistant. You're collaborating with teammate who speaks English. Please respond in English.") # rubocop:disable Layout/LineLength
    end
  end

  describe "#requested_language_key" do
    it "does not permit invalid language keys" do
      completion = FB.build(:sentinel_completion, requested_language_key: "invalid")
      expect(completion.valid?).to eq(false)
      expect(completion.errors[:requested_language_key]).to include("is not included in the list")
    end
  end

  describe "#llm_model_name" do
    it "does not permit invalid model names" do
      completion = FB.build(:sentinel_completion, llm_model_name: "invalid")
      expect(completion.valid?).to eq(false)
      expect(completion.errors[:llm_model_name]).to include("is not included in the list")
    end
  end
end
