# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::AgentInvocations", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "index page" do
    let!(:pending_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "What is the capital of France?",
        max_iterations: 5
      )
    end

    let!(:running_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "List the planets in our solar system",
        started_at: 2.minutes.ago,
        iteration_count: 2,
        max_iterations: 5
      )
    end

    let!(:completed_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "Calculate 15 * 24",
        started_at: 5.minutes.ago,
        completed_at: 4.minutes.ago,
        iteration_count: 3,
        max_iterations: 5,
        final_answer: "The result of 15 * 24 is 360."
      )
    end

    let!(:failed_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "This task will fail",
        started_at: 10.minutes.ago,
        failed_at: 9.minutes.ago,
        iteration_count: 1,
        max_iterations: 5
      )
    end

    let!(:long_task_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "a" * 200,
        max_iterations: 10
      )
    end

    it "displays agent invocations with all details and handles edge cases" do
      visit sentinel.admin_agent_invocations_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("sentinel.admin.common.agent_invocations"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.id"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.created_at"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.task"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.status"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.iterations"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.final_answer"))

      # Check agent invocations count and status badges
      expect(page).to have_css("tr.sentinel-agent-invocation", count: 5) # Total number of agent invocations
      expect(page).to have_css(".badge.bg-success", text: "Completed")
      expect(page).to have_css(".badge.bg-danger", text: "Failed")
      expect(page).to have_css(".badge.bg-warning", text: "Running")
      expect(page).to have_css(".badge.bg-secondary", text: "Pending")

      # Check iteration counts
      expect(page).to have_content("0 / 5") # pending_invocation
      expect(page).to have_content("2 / 5") # running_invocation
      expect(page).to have_content("3 / 5") # completed_invocation
      expect(page).to have_content("1 / 5") # failed_invocation
      expect(page).to have_content("0 / 10") # long_task_invocation

      # Check final answer
      expect(page).to have_content("The result of 15 * 24 is 360.")

      # Truncated long task
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::AgentInvocation.destroy_all
      visit sentinel.admin_agent_invocations_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.no_agent_invocations"))
    end
  end

  describe "show page" do
    let!(:agent_invocation) do
      FB.create(
        :sentinel_agent_invocation,
        creator: creator,
        task: "What is the capital of France?",
        started_at: 5.minutes.ago,
        completed_at: 4.minutes.ago,
        iteration_count: 2,
        max_iterations: 5,
        final_answer: "The capital of France is Paris.",
        llm_model_key: "open_ai_gpt_4o",
        conversation_history: [
          { role: "user", content: "What is the capital of France?" },
          { role: "assistant", content: "<thought>I need to determine the capital of France.</thought>" },
          { role: "assistant", content: "<answer>The capital of France is Paris.</answer>" }
        ]
      )
    end

    let!(:model_completion) do
      Raif::ModelCompletions::OpenAi.create!(
        source: agent_invocation,
        llm_model_key: "open_ai_gpt_4o",
        model_api_name: "gpt-4o",
        response_format: "text",
        raw_response: "<thought>I need to determine the capital of France.</thought>\n<answer>The capital of France is Paris.</answer>",
        total_tokens: 150
      )
    end

    before do
      visit sentinel.admin_agent_invocation_path(agent_invocation)
    end

    it "displays the agent invocation details and has a back link to the index" do
      expect(page).to have_content(I18n.t("sentinel.admin.agent_invocations.show.title", id: agent_invocation.id))

      # Check basic details
      expect(page).to have_content(agent_invocation.id.to_s)
      expect(page).to have_content(agent_invocation.creator_type)
      expect(page).to have_content(agent_invocation.creator_id.to_s)
      expect(page).to have_content("open_ai_gpt_4o")

      # Check status
      expect(page).to have_css(".badge.bg-success", text: "Completed")
      expect(page).to have_content(agent_invocation.completed_at.rfc822)

      # Check iterations
      expect(page).to have_content("2 / 5")

      # Check task and final answer
      expect(page).to have_content("What is the capital of France?")
      expect(page).to have_content("The capital of France is Paris.")

      # Check system prompt
      expect(page).to have_content(agent_invocation.system_prompt.first(100))

      # Check conversation history
      expect(page).to have_content("What is the capital of France?")
      expect(page).to have_content("I need to determine the capital of France.")
      expect(page).to have_content("The capital of France is Paris.")

      # Check model completions section
      expect(page).to have_content(I18n.t("sentinel.admin.common.model_completions"))
      expect(page).to have_link("##{model_completion.id}", href: sentinel.admin_model_completion_path(model_completion))
      expect(page).to have_content(model_completion.created_at.rfc822)
      expect(page).to have_content("open_ai_gpt_4o")
      expect(page).to have_content("150")
      expect(page).to have_content("<thought>I need to determine the capital of France.</thought>")

      # Check back link functionality
      expect(page).to have_link(I18n.t("sentinel.admin.agent_invocations.show.back_to_agent_invocations"), href: sentinel.admin_agent_invocations_path)

      click_link I18n.t("sentinel.admin.agent_invocations.show.back_to_agent_invocations")
      expect(page).to have_current_path(sentinel.admin_agent_invocations_path)
    end
  end
end
