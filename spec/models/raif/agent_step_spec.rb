# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::AgentStep, type: :model do
  describe "tag extraction" do
    context "with a complete response containing all tags" do
      let(:model_response_text) do
        <<~RESPONSE
          <thought>I need to find information about Paris.</thought>
          <action>{"tool": "search", "arguments": {"query": "Paris facts"}}</action>
          <answer>Paris is the capital of France.</answer>
        RESPONSE
      end

      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "extracts the thought" do
        expect(step.thought).to eq("I need to find information about Paris.")
      end

      it "extracts the action" do
        expect(step.action).to eq('{"tool": "search", "arguments": {"query": "Paris facts"}}')
      end

      it "extracts the answer" do
        expect(step.answer).to eq("Paris is the capital of France.")
      end
    end

    context "with a response containing only thought and answer" do
      let(:model_response_text) do
        <<~RESPONSE
          <thought>I already know the capital of France.</thought>
          <answer>The capital of France is Paris.</answer>
        RESPONSE
      end

      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "extracts the thought" do
        expect(step.thought).to eq("I already know the capital of France.")
      end

      it "returns nil for action" do
        expect(step.action).to be_nil
      end

      it "extracts the answer" do
        expect(step.answer).to eq("The capital of France is Paris.")
      end
    end

    context "with a response containing only thought and action" do
      let(:model_response_text) do
        <<~RESPONSE
          <thought>I need to search for information.</thought>
          <action>{"tool": "search", "arguments": {"query": "Paris"}}</action>
        RESPONSE
      end

      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "extracts the thought" do
        expect(step.thought).to eq("I need to search for information.")
      end

      it "extracts the action" do
        expect(step.action).to eq('{"tool": "search", "arguments": {"query": "Paris"}}')
      end

      it "returns nil for answer" do
        expect(step.answer).to be_nil
      end
    end

    context "with a response containing multiline content" do
      let(:model_response_text) do
        <<~RESPONSE
          <thought>
          I need to find information about Paris.
          It's an important city in Europe.
          </thought>
          <action>{"tool": "search", "arguments": {"query": "Paris facts"}}</action>
        RESPONSE
      end

      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "extracts the multiline thought" do
        expected = "I need to find information about Paris.\nIt's an important city in Europe."
        expect(step.thought).to eq(expected)
      end
    end

    context "with a response containing no tags" do
      let(:model_response_text) { "This is just plain text with no tags." }
      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "returns nil for all extractions" do
        expect(step.thought).to be_nil
        expect(step.action).to be_nil
        expect(step.answer).to be_nil
      end
    end

    context "with a response containing malformed tags" do
      let(:model_response_text) do
        <<~RESPONSE
          <thought>Incomplete thought
          <action>{"tool": "search"}</action>
        RESPONSE
      end

      subject(:step) { described_class.new(model_response_text: model_response_text) }

      it "returns nil for malformed tags" do
        expect(step.thought).to be_nil
      end

      it "extracts properly formed tags" do
        expect(step.action).to eq('{"tool": "search"}')
      end
    end
  end
end
