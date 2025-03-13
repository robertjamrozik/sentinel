# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Agent, type: :model do
  let(:creator) { FB.create(:sentinel_test_user) }
  let(:task) { "What is the capital of France?" }
  let(:tools) { [] }

  describe "#system_prompt" do
    let(:agent) { described_class.new(task: task, tools: tools, creator: creator) }

    it "includes instructions about the ReAct framework" do
      response_prompt = <<~RESPONSE_PROMPT
        # Your Responses
        Your responses should follow this structure & format:
        <thought>Your step-by-step reasoning about what to do</thought>
        <action>JSON object with "tool" and "arguments" keys</action>
        <observation>Results from the tool, which will be provided to you</observation>
        ... (repeat Thought/Action/Observation as needed until the task is complete)
        <thought>Final reasoning based on all observations</thought>
        <answer>Your final response to the user</answer>
      RESPONSE_PROMPT

      expect(agent.system_prompt).to include("You are an intelligent assistant that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool calls.") # rubocop:disable Layout/LineLength
      expect(agent.system_prompt).to include(response_prompt)
    end

    context "with available tools" do
      let(:tools) { [Raif::TestModelTool, Raif::ModelTools::WikipediaSearchTool] }

      it "includes tool descriptions in the prompt" do
        tool_descriptions = <<~PROMPT
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
        PROMPT

        expect(agent.system_prompt).to include(tool_descriptions)
      end
    end
  end

  describe "#run!" do
    let(:agent) { described_class.new(task: task, tools: tools, creator: creator) }
    let(:agent_invocation) { instance_double(Raif::AgentInvocation) }

    before do
      allow(Raif::AgentInvocation).to receive(:new).and_return(agent_invocation)
      allow(agent_invocation).to receive(:run!).and_return("Paris is the capital of France.")
    end

    it "creates a new agent invocation with the correct attributes" do
      expect(Raif::AgentInvocation).to receive(:new).with(
        task: task,
        available_model_tools: tools,
        system_prompt: agent.system_prompt,
        creator: creator,
        requested_language_key: nil,
        llm_model_key: nil,
        max_iterations: 10
      )

      agent.run!
    end

    it "runs the agent invocation" do
      expect(agent_invocation).to receive(:run!)
      agent.run!
    end

    it "returns the agent invocation" do
      expect(agent.run!).to eq(agent_invocation)
    end
  end
end
