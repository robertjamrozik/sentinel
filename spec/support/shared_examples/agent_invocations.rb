# frozen_string_literal: true

RSpec.shared_examples "an agent invocation" do |parameter|
  describe "validations" do
    it "validates presence of task" do
      invocation = described_class.new(
        creator: creator,
        system_prompt: "System prompt",
        max_iterations: 5,
        available_model_tools: [Raif::TestModelTool]
      )
      expect(invocation).not_to be_valid
      expect(invocation.errors[:task]).to include("can't be blank")
    end

    it "validates presence of system_prompt" do
      invocation = described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        max_iterations: 5,
        available_model_tools: [Raif::TestModelTool]
      )

      allow(invocation).to receive(:build_system_prompt).and_return(nil)
      expect(invocation).not_to be_valid
      expect(invocation.errors[:system_prompt]).to include("can't be blank")
    end

    it "validates the length of available_model_tools" do
      invocation = described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "System prompt",
      )
      expect(invocation).not_to be_valid
      expect(invocation.errors[:available_model_tools]).to include("must have at least 1 tool")
    end

    it "validates presence and numericality of max_iterations" do
      invocation = described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "System prompt",
        available_model_tools: [Raif::TestModelTool]
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
end
