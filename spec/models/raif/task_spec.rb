# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Task, type: :model do
  describe "#build_system_prompt" do
    it "returns the system prompt with no language preference" do
      task = FB.build(:sentinel_task)
      expect(task.requested_language_key).to be_nil
      expect(task.build_system_prompt).to eq("You are a helpful assistant.")
    end

    it "returns the system prompt with the language preference" do
      task = FB.build(:sentinel_task, requested_language_key: "en")
      expect(task.build_system_prompt).to eq("You are a helpful assistant.\nYou're collaborating with teammate who speaks English. Please respond in English.") # rubocop:disable Layout/LineLength
    end
  end

  describe "#requested_language_key" do
    it "does not permit invalid language keys" do
      task = FB.build(:sentinel_task, requested_language_key: "invalid")
      expect(task.valid?).to eq(false)
      expect(task.errors[:requested_language_key]).to include("is not included in the list")
    end
  end

  describe "#llm_model_key" do
    it "does not permit invalid model names" do
      task = FB.build(:sentinel_task, llm_model_key: "invalid")
      expect(task.valid?).to eq(false)
      expect(task.errors[:llm_model_key]).to include("is not included in the list")
    end
  end
end
