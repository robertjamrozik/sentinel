# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::AgentInvocation, type: :model do
  let(:creator) { FB.create(:sentinel_test_user) }

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

  describe "#run!" do
    let(:invocation) do
      described_class.new(
        creator: creator,
        task: "What is the capital of France?",
        system_prompt: "You are a helpful assistant.",
        max_iterations: 3,
        available_model_tools: [Raif::ModelTools::WikipediaSearchTool, Raif::ModelTools::FetchUrlTool],
        llm_model_key: "open_ai_gpt_4o"
      )
    end

    before do
      stub_sentinel_agent_invocation(invocation) do |_messages|
        "<thought>I know this.</thought>\n<answer>Paris</answer>"
      end
    end

    it "runs the agent" do
      expect(invocation.started_at).to be_nil
      expect(invocation.completed_at).to be_nil
      expect(invocation.failed_at).to be_nil

      invocation.run!

      expect(invocation.started_at).to be_present
      expect(invocation.completed_at).to be_present
      expect(invocation.failed_at).to be_nil

      expect(invocation.conversation_history).to eq([
        { "role" => "user", "content" => "What is the capital of France?" },
        { "role" => "assistant", "content" => "<thought>I know this.</thought>" },
        { "role" => "assistant", "content" => "<answer>Paris</answer>" }
      ])

      expect(invocation.final_answer).to eq("Paris")
    end

    context "with multiple iterations" do
      before do
        stub_request(:get, "https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srlimit=5&srprop=snippet&srsearch=capital%20of%20France")
          .to_return(status: 200, body: "{\"batchcomplete\":\"\",\"continue\":{\"sroffset\":5,\"continue\":\"-||\"},\"query\":{\"searchinfo\":{\"totalhits\":93901},\"search\":[{\"ns\":0,\"title\":\"List of capitals of France\",\"pageid\":169335,\"snippet\":\"This is a chronological list <span class=\\\"searchmatch\\\">of</span> capitals <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span>. The <span class=\\\"searchmatch\\\">capital</span> <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span> has been Paris since its liberation in 1944. Tournai (before 486), current-day\"},{\"ns\":0,\"title\":\"Capital punishment in France\",\"pageid\":2861364,\"snippet\":\"<span class=\\\"searchmatch\\\">Capital</span> punishment in <span class=\\\"searchmatch\\\">France</span> (<span class=\\\"searchmatch\\\">French</span>: peine de mort en <span class=\\\"searchmatch\\\">France</span>) is banned by Article 66-1 <span class=\\\"searchmatch\\\">of</span> the Constitution <span class=\\\"searchmatch\\\">of</span> the <span class=\\\"searchmatch\\\">French</span> Republic, voted as a constitutional\"},{\"ns\":0,\"title\":\"Capital city\",\"pageid\":181337,\"snippet\":\"seat <span class=\\\"searchmatch\\\">of</span> the government. A <span class=\\\"searchmatch\\\">capital</span> is typically a city that physically encompasses the government&#039;s offices and meeting places; the status as <span class=\\\"searchmatch\\\">capital</span> is\"},{\"ns\":0,\"title\":\"Capital\",\"pageid\":5187,\"snippet\":\"Piketty, 2013 <span class=\\\"searchmatch\\\">Capital</span>: The Eruption <span class=\\\"searchmatch\\\">of</span> Delhi, a 2014 book by Rana Dasgupta <span class=\\\"searchmatch\\\">Capital</span> (<span class=\\\"searchmatch\\\">French</span> magazine), a <span class=\\\"searchmatch\\\">French</span>-language magazine <span class=\\\"searchmatch\\\">Capital</span> (German magazine)\"},{\"ns\":0,\"title\":\"Paris\",\"pageid\":22989,\"snippet\":\"Paris (<span class=\\\"searchmatch\\\">French</span> pronunciation: [pa\\u0281i] ) is the <span class=\\\"searchmatch\\\">capital</span> and largest city <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span>. With an estimated population <span class=\\\"searchmatch\\\">of</span> 2,048,472 residents in January 2025 in\"}]}}") # rubocop:disable Layout/LineLength
      end

      it "processes multiple iterations until finding an answer" do
        i = 0
        stub_sentinel_agent_invocation(invocation) do |_messages|
          i += 1
          if i == 1
            "<thought>I need to search.</thought>\n<action>{\"tool\": \"wikipedia_search\", \"arguments\": {\"query\": \"capital of France\"}}</action>" # rubocop:disable Layout/LineLength
          else
            "<thought>Now I know.</thought>\n<answer>Paris</answer>"
          end
        end

        expect(invocation.started_at).to be_nil
        expect(invocation.completed_at).to be_nil
        expect(invocation.failed_at).to be_nil

        invocation.run!

        expect(invocation.started_at).to be_present
        expect(invocation.completed_at).to be_present
        expect(invocation.failed_at).to be_nil
        expect(invocation.final_answer).to eq("Paris")

        expect(invocation.conversation_history).to eq([
          { "role" => "user", "content" => "What is the capital of France?" },
          { "role" => "assistant", "content" => "<thought>I need to search.</thought>" },
          {
            "role" => "assistant",
            "content" => "<action>{\"tool\": \"wikipedia_search\", \"arguments\": {\"query\": \"capital of France\"}}</action>"
          },
          {
            "role" => "user",
            "content" =>
            "<observation>{\n  \"results\": [\n    {\n      \"title\": \"List of capitals of France\",\n      \"snippet\": \"This is a chronological list <span class=\\\"searchmatch\\\">of</span> capitals <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span>. The <span class=\\\"searchmatch\\\">capital</span> <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span> has been Paris since its liberation in 1944. Tournai (before 486), current-day\",\n      \"page_id\": 169335,\n      \"url\": \"https://en.wikipedia.org/wiki/List_of_capitals_of_France\"\n    },\n    {\n      \"title\": \"Capital punishment in France\",\n      \"snippet\": \"<span class=\\\"searchmatch\\\">Capital</span> punishment in <span class=\\\"searchmatch\\\">France</span> (<span class=\\\"searchmatch\\\">French</span>: peine de mort en <span class=\\\"searchmatch\\\">France</span>) is banned by Article 66-1 <span class=\\\"searchmatch\\\">of</span> the Constitution <span class=\\\"searchmatch\\\">of</span> the <span class=\\\"searchmatch\\\">French</span> Republic, voted as a constitutional\",\n      \"page_id\": 2861364,\n      \"url\": \"https://en.wikipedia.org/wiki/Capital_punishment_in_France\"\n    },\n    {\n      \"title\": \"Capital city\",\n      \"snippet\": \"seat <span class=\\\"searchmatch\\\">of</span> the government. A <span class=\\\"searchmatch\\\">capital</span> is typically a city that physically encompasses the government&#039;s offices and meeting places; the status as <span class=\\\"searchmatch\\\">capital</span> is\",\n      \"page_id\": 181337,\n      \"url\": \"https://en.wikipedia.org/wiki/Capital_city\"\n    },\n    {\n      \"title\": \"Capital\",\n      \"snippet\": \"Piketty, 2013 <span class=\\\"searchmatch\\\">Capital</span>: The Eruption <span class=\\\"searchmatch\\\">of</span> Delhi, a 2014 book by Rana Dasgupta <span class=\\\"searchmatch\\\">Capital</span> (<span class=\\\"searchmatch\\\">French</span> magazine), a <span class=\\\"searchmatch\\\">French</span>-language magazine <span class=\\\"searchmatch\\\">Capital</span> (German magazine)\",\n      \"page_id\": 5187,\n      \"url\": \"https://en.wikipedia.org/wiki/Capital\"\n    },\n    {\n      \"title\": \"Paris\",\n      \"snippet\": \"Paris (<span class=\\\"searchmatch\\\">French</span> pronunciation: [paʁi] ) is the <span class=\\\"searchmatch\\\">capital</span> and largest city <span class=\\\"searchmatch\\\">of</span> <span class=\\\"searchmatch\\\">France</span>. With an estimated population <span class=\\\"searchmatch\\\">of</span> 2,048,472 residents in January 2025 in\",\n      \"page_id\": 22989,\n      \"url\": \"https://en.wikipedia.org/wiki/Paris\"\n    }\n  ]\n}</observation>" # rubocop:disable Layout/LineLength
          },
          { "role" => "assistant", "content" => "<thought>Now I know.</thought>" },
          { "role" => "assistant", "content" => "<answer>Paris</answer>" }
        ])

        expect(invocation.sentinel_model_tool_invocations.length).to eq(1)
        mti = invocation.sentinel_model_tool_invocations.first
        expect(mti.tool_name).to eq("wikipedia_search")
        expect(mti.tool_type).to eq("Raif::ModelTools::WikipediaSearchTool")
        expect(mti.tool_arguments).to eq({ "query" => "capital of France" })

        expect(mti.result).to eq({
          "results" => [
            {
              "url" => "https://en.wikipedia.org/wiki/List_of_capitals_of_France",
              "title" => "List of capitals of France",
              "page_id" => 169335,
              "snippet" => "This is a chronological list <span class=\"searchmatch\">of</span> capitals <span class=\"searchmatch\">of</span> <span class=\"searchmatch\">France</span>. The <span class=\"searchmatch\">capital</span> <span class=\"searchmatch\">of</span> <span class=\"searchmatch\">France</span> has been Paris since its liberation in 1944. Tournai (before 486), current-day" # rubocop:disable Layout/LineLength
            },
            {
              "url" => "https://en.wikipedia.org/wiki/Capital_punishment_in_France",
              "title" => "Capital punishment in France",
              "page_id" => 2861364,
              "snippet" => "<span class=\"searchmatch\">Capital</span> punishment in <span class=\"searchmatch\">France</span> (<span class=\"searchmatch\">French</span>: peine de mort en <span class=\"searchmatch\">France</span>) is banned by Article 66-1 <span class=\"searchmatch\">of</span> the Constitution <span class=\"searchmatch\">of</span> the <span class=\"searchmatch\">French</span> Republic, voted as a constitutional" # rubocop:disable Layout/LineLength
            },
            {
              "url" => "https://en.wikipedia.org/wiki/Capital_city",
              "title" => "Capital city",
              "page_id" => 181337,
              "snippet" => "seat <span class=\"searchmatch\">of</span> the government. A <span class=\"searchmatch\">capital</span> is typically a city that physically encompasses the government&#039;s offices and meeting places; the status as <span class=\"searchmatch\">capital</span> is" # rubocop:disable Layout/LineLength
            },
            {
              "url" => "https://en.wikipedia.org/wiki/Capital",
              "title" => "Capital",
              "page_id" => 5187,
              "snippet" => "Piketty, 2013 <span class=\"searchmatch\">Capital</span>: The Eruption <span class=\"searchmatch\">of</span> Delhi, a 2014 book by Rana Dasgupta <span class=\"searchmatch\">Capital</span> (<span class=\"searchmatch\">French</span> magazine), a <span class=\"searchmatch\">French</span>-language magazine <span class=\"searchmatch\">Capital</span> (German magazine)" # rubocop:disable Layout/LineLength
            },
            {
              "url" => "https://en.wikipedia.org/wiki/Paris",
              "title" => "Paris",
              "page_id" => 22989,
              "snippet" => "Paris (<span class=\"searchmatch\">French</span> pronunciation: [paʁi] ) is the <span class=\"searchmatch\">capital</span> and largest city <span class=\"searchmatch\">of</span> <span class=\"searchmatch\">France</span>. With an estimated population <span class=\"searchmatch\">of</span> 2,048,472 residents in January 2025 in" # rubocop:disable Layout/LineLength
            }
          ]
        })
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
        { "role" => "user", "content" => "<observation>Mock Observation</observation>" }
      )
    end

    it "handles an action with an unavailable tool" do
      action = {
        "tool" => "unavailable_tool",
        "arguments" => { "query" => "capital of France" }
      }

      invocation.process_action(action)

      expect(invocation.conversation_history).to include(
        { "role" => "user", "content" => include("Error: Tool 'unavailable_tool' not found. Available tools: test_model") }
      )
    end
  end

  describe "#build_system_prompt" do
    let(:task) { "What is the capital of France?" }
    let(:tools) { [Raif::TestModelTool, Raif::ModelTools::WikipediaSearchTool] }
    let(:agent_invocation) { described_class.new(task: task, available_model_tools: tools, creator: creator) }
    let(:system_prompt) { agent_invocation.build_system_prompt }

    it "includes tool descriptions in the prompt" do
      prompt = <<~PROMPT
        You are an intelligent assistant that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool calls.

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


        # Your Responses
        Your responses should follow this structure & format:
        <thought>Your step-by-step reasoning about what to do</thought>
        <action>JSON object with "tool" and "arguments" keys</action>
        <observation>Results from the tool, which will be provided to you</observation>
        ... (repeat Thought/Action/Observation as needed until the task is complete)
        <thought>Final reasoning based on all observations</thought>
        <answer>Your final response to the user</answer>

        # How to Use Tools
        When you need to use a tool:
        1. Identify which tool is appropriate for the task
        2. Format your tool call using JSON with the required arguments and place it in the <action> tag
        3. Here is an example: <action>{"tool": "tool_name", "arguments": {...}}</action>

        # Guidelines
        - Always think step by step
        - Use tools when appropriate, but don't use tools for tasks you can handle directly
        - Be concise in your reasoning but thorough in your analysis
        - If a tool returns an error, try to understand why and adjust your approach
        - If you're unsure about something, explain your uncertainty, but do not make things up
        - After each thought, make sure to also include an <action> or <answer>
        - Always provide a final answer that directly addresses the user's request

        Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.
      PROMPT

      expect(agent_invocation.build_system_prompt).to eq(prompt)
    end

    context "when requested language is set" do
      let(:agent_invocation) { described_class.new(task: task, available_model_tools: tools, creator: creator, requested_language_key: "fr") }

      it "includes the requested language in the prompt" do
        prompt = <<~PROMPT
          You are an intelligent assistant that follows the ReAct (Reasoning + Acting) framework to complete tasks step by step using tool calls.

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


          # Your Responses
          Your responses should follow this structure & format:
          <thought>Your step-by-step reasoning about what to do</thought>
          <action>JSON object with "tool" and "arguments" keys</action>
          <observation>Results from the tool, which will be provided to you</observation>
          ... (repeat Thought/Action/Observation as needed until the task is complete)
          <thought>Final reasoning based on all observations</thought>
          <answer>Your final response to the user</answer>

          # How to Use Tools
          When you need to use a tool:
          1. Identify which tool is appropriate for the task
          2. Format your tool call using JSON with the required arguments and place it in the <action> tag
          3. Here is an example: <action>{"tool": "tool_name", "arguments": {...}}</action>

          # Guidelines
          - Always think step by step
          - Use tools when appropriate, but don't use tools for tasks you can handle directly
          - Be concise in your reasoning but thorough in your analysis
          - If a tool returns an error, try to understand why and adjust your approach
          - If you're unsure about something, explain your uncertainty, but do not make things up
          - After each thought, make sure to also include an <action> or <answer>
          - Always provide a final answer that directly addresses the user's request

          Remember: Your goal is to be helpful, accurate, and efficient in solving the user's request.
          You're collaborating with teammate who speaks French. Please respond in French.
        PROMPT

        expect(agent_invocation.build_system_prompt).to eq(prompt)
      end
    end
  end
end
