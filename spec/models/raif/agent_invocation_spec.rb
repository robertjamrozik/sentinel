# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::AgentInvocation, type: :model do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "validations" do
    it "validates presence of task" do
      invocation = described_class.new(
        creator: creator,
        system_prompt: "System prompt",
        max_iterations: 5
      )
      expect(invocation).not_to be_valid
      expect(invocation.errors[:task]).to include("can't be blank")
    end

    it "validates presence of system_prompt" do
      invocation = described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        max_iterations: 5
      )
      expect(invocation).not_to be_valid
      expect(invocation.errors[:system_prompt]).to include("can't be blank")
    end

    it "validates presence and numericality of max_iterations" do
      invocation = described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "System prompt"
      )
      expect(invocation.max_iterations).to eq(10)
      expect(invocation).to be_valid

      invocation.max_iterations = nil
      expect(invocation).not_to be_valid
      expect(invocation.errors[:max_iterations]).to include("can't be blank")

      invocation.max_iterations = 0
      expect(invocation).not_to be_valid
      expect(invocation.errors[:max_iterations]).to include("must be greater than 0")
    end
  end

  describe "#run!" do
    let(:invocation) do
      described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "You are a helpful assistant.",
        max_iterations: 3,
        llm_model_key: "open_ai_gpt_4o"
      )
    end

    let(:llm) { instance_double(Raif::Llm) }
    let(:model_completion) { Raif::ModelCompletion.new(raw_response: "<thought>I know this.</thought>\n<answer>Paris</answer>") }

    before do
      allow(invocation).to receive(:llm).and_return(llm)
      allow(llm).to receive(:chat).and_return(model_completion)
      allow(invocation).to receive(:save!).and_return(true)
      allow(invocation).to receive(:update_columns).and_return(true)
      allow(invocation).to receive(:completed!).and_return(true)
    end

    it "sets started_at timestamp" do
      expect { invocation.run! }.to change { invocation.started_at }.from(nil).to(be_present)
    end

    it "adds the task to conversation history" do
      invocation.run!
      expect(invocation.conversation_history).to include(
        { role: "user", content: "What is the capital of France?" }
      )
    end

    it "calls the LLM with the correct parameters" do
      expect(llm).to receive(:chat).with(
        messages: [{ role: "user", content: "What is the capital of France?" }],
        source: invocation,
        system_prompt: "You are a helpful assistant."
      )
      invocation.run!
    end

    it "extracts thought and answer from the model response" do
      invocation.run!
      expect(invocation.conversation_history).to include(
        { role: "assistant", content: "<thought>I know this.</thought>" }
      )
      expect(invocation.conversation_history).to include(
        { role: "assistant", content: "<answer>Paris</answer>" }
      )
    end

    it "sets the final answer" do
      invocation.run!
      expect(invocation.final_answer).to eq("Paris")
    end

    it "marks the invocation as completed" do
      expect(invocation).to receive(:completed!)
      invocation.run!
    end

    it "returns the final answer" do
      expect(invocation.run!).to eq("Paris")
    end

    context "with multiple iterations" do
      let(:first_response) do
        instance_double(
          Raif::ModelCompletion,
          raw_response: "<thought>I need to search.</thought>\n<action>{\"tool\": \"search\", \"arguments\": {\"query\": \"capital of France\"}}</action>" # rubocop:disable Layout/LineLength
        )
      end
      let(:second_response) { instance_double(Raif::ModelCompletion, raw_response: "<thought>Now I know.</thought>\n<answer>Paris</answer>") }

      before do
        allow(llm).to receive(:chat).and_return(first_response, second_response)
        allow(invocation).to receive(:process_action).and_return(nil)
      end

      it "processes multiple iterations until finding an answer" do
        expect(llm).to receive(:chat).twice
        expect(invocation).to receive(:process_action).once
        invocation.run!
        expect(invocation.final_answer).to eq("Paris")
      end
    end
  end

  describe "#process_action" do
    let(:invocation) do
      described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "You are a helpful assistant.",
        max_iterations: 3,
        available_model_tools: [Raif::TestModelTool]
      )
    end

    it "processes a valid action with an available tool" do
      action = {
        "tool" => "test_model",
        "arguments" => [{ "title" => "foo", "description" => "bar" }]
      }

      invocation.process_action(action)

      expect(invocation.conversation_history).to include(
        { role: "user", content: "<observation>Mock Observation</observation>" }
      )
    end

    it "handles an action with an unavailable tool" do
      action = {
        "tool" => "unavailable_tool",
        "arguments" => { "query" => "capital of France" }
      }

      invocation.process_action(action)

      expect(invocation.conversation_history).to include(
        { role: "user", content: include("Error: Tool 'unavailable_tool' not found. Available tools: test_model") }
      )
    end
  end
end
