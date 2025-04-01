# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tasks", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "index page" do
    let!(:tasks) { FB.create_list(:sentinel_test_task, 2, creator: creator) }
    let!(:completed_task){ FB.create(:sentinel_test_task, :completed, creator: creator) }
    let!(:failed_task){ FB.create(:sentinel_test_task, :failed, creator: creator) }
    let!(:in_progress_task){ FB.create(:sentinel_test_task, creator: creator, started_at: 1.minute.ago) }
    let!(:long_prompt_task) do
      FB.create(:sentinel_test_task, prompt: "a" * 200, creator: creator)
    end

    it "displays tasks with all details, allows navigation, and handles edge cases" do
      visit sentinel.admin_tasks_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("sentinel.admin.common.tasks"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.id"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.created_at"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.creator"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.model"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.status"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.prompt"))

      # Check tasks count and status badges
      expect(page).to have_css("tr.sentinel-task", count: 6) # Total number of tasks
      expect(page).to have_css(".badge.bg-success", text: I18n.t("sentinel.admin.common.completed"))
      expect(page).to have_css(".badge.bg-danger", text: I18n.t("sentinel.admin.common.failed"))
      expect(page).to have_css(".badge.bg-warning", text: I18n.t("sentinel.admin.common.in_progress"))
      expect(page).to have_css(".badge.bg-secondary", text: I18n.t("sentinel.admin.common.pending"))

      # Truncated long prompt
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::Task.delete_all
      visit sentinel.admin_tasks_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.no_tasks"))
    end
  end

  describe "show page" do
    let!(:task) do
      FB.create(
        :sentinel_test_task,
        :completed,
        creator: creator,
        prompt: "Test prompt",
        raw_response: "Test response",
        system_prompt: "You are a test assistant",
        llm_model_key: "open_ai_gpt_4o_mini"
      )
    end

    before do
      visit sentinel.admin_task_path(task)
    end

    it "displays the task details and has a back link to the tasks index" do
      expect(page).to have_content(I18n.t("sentinel.admin.tasks.show.title", id: task.id))

      # Check basic details
      expect(page).to have_content(task.id.to_s)
      expect(page).to have_content(task.creator_type)
      expect(page).to have_content(task.creator_id.to_s)
      expect(page).to have_content("open_ai_gpt_4o_mini")
      expect(page).to have_content(task.response_format)

      # Check timestamps
      expect(page).to have_content(task.created_at.rfc822)
      expect(page).to have_content(task.started_at.rfc822)
      expect(page).to have_content(task.completed_at.rfc822)

      # Check prompt and response
      expect(page).to have_content("Test prompt")
      expect(page).to have_content("Test response")
      expect(page).to have_content("You are a test assistant")

      # Check back link functionality
      expect(page).to have_link(I18n.t("sentinel.admin.tasks.show.back_to_tasks"), href: sentinel.admin_tasks_path)

      click_link I18n.t("sentinel.admin.tasks.show.back_to_tasks")
      expect(page).to have_current_path(sentinel.admin_tasks_path)
    end

    context "with model_completion" do
      let!(:model_completion) do
        FB.create(
          :sentinel_model_completion,
          source: task,
          llm_model_key: task.llm_model_key,
          model_api_name: Raif.llm(task.llm_model_key.to_sym).api_name,
          raw_response: "Test model response",
          prompt_tokens: 1000,
          completion_tokens: 20,
          total_tokens: 1020
        )
      end

      it "displays the model_completion section" do
        visit sentinel.admin_task_path(task)

        # Check model_completion section exists
        expect(page).to have_content(I18n.t("sentinel.admin.common.model_completion"))

        # Check model_completion details
        expect(page).to have_link("##{model_completion.id}", href: sentinel.admin_model_completion_path(model_completion))
        expect(page).to have_content(model_completion.created_at.rfc822)
        expect(page).to have_content("1,000") # prompt_tokens
        expect(page).to have_content("20") # completion_tokens
        expect(page).to have_content("1,020") # total_tokens
      end
    end
  end
end
