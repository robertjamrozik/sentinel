# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Stats::Tasks", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "index page" do
    # Create tasks of different types
    let!(:task1) { FB.create(:sentinel_test_task, creator: creator, created_at: 12.hours.ago) }
    let!(:task2) { FB.create(:sentinel_test_task, :completed, creator: creator, created_at: 12.hours.ago) }
    let!(:task3) { FB.create(:sentinel_test_task, creator: creator, created_at: 12.hours.ago) }

    # Create model completions for tasks to test cost calculations
    let!(:model_completion1) do
      FB.create(
        :sentinel_model_completion,
        llm_model_key: "anthropic_claude_3_7_sonnet",
        model_api_name: "claude-3-7-sonnet-latest",
        source: task1,
        prompt_tokens: 100,
        completion_tokens: 50,
        created_at: 12.hours.ago
      )
    end

    let!(:model_completion2) do
      FB.create(
        :sentinel_model_completion,
        llm_model_key: "open_ai_gpt_4o",
        model_api_name: "gpt-4o",
        source: task2,
        prompt_tokens: 200,
        completion_tokens: 100,
        created_at: 12.hours.ago
      )
    end

    # Create older task of a different type
    let!(:old_task) { FB.create(:sentinel_test_task, :failed, creator: creator, created_at: 2.days.ago) }
    let!(:old_model_completion) do
      FB.create(
        :sentinel_model_completion,
        llm_model_key: "open_ai_gpt_4o_mini",
        model_api_name: "gpt-4o-mini",
        source: old_task,
        prompt_tokens: 300,
        completion_tokens: 150,
        created_at: 2.days.ago
      )
    end

    it "displays task stats by type with counts and costs for different periods" do
      visit sentinel.admin_stats_tasks_path

      # Check page title and back link
      expect(page).to have_content(I18n.t("sentinel.admin.stats.tasks.title"))
      expect(page).to have_link(I18n.t("sentinel.admin.stats.tasks.back_to_stats"), href: sentinel.admin_stats_path)

      # Check period filter has day selected by default
      expect(page).to have_select("period", selected: I18n.t("sentinel.admin.common.period_day"))

      # Check table headers
      within("table thead") do
        expect(page).to have_content(I18n.t("sentinel.admin.common.type"))
        expect(page).to have_content(I18n.t("sentinel.admin.common.count"))
        expect(page).to have_content(I18n.t("sentinel.admin.common.est_cost"))
      end

      # For day period, we should only see tasks from the last 24 hours
      within("table tbody") do
        # Check that we have task types listed with their counts
        expect(page).to have_content(task1.type)

        # Check task count for the type
        task_count = page.find("td", text: task1.type).sibling("td", match: :first).text
        expect(task_count).to eq("3") # We have 3 tasks of this type in the last 24 hours

        # Check that cost is displayed
        expect(page).to have_content("$0.002550")
      end

      # Change period to "all"
      select I18n.t("sentinel.admin.common.period_all"), from: "period"
      click_button I18n.t("sentinel.admin.common.update")

      # Now we should see all tasks including the older one
      within("table tbody") do
        # If old task is same type, the count should increase by 1
        task_count = page.find("td", text: task1.type).sibling("td", match: :first).text
        expect(task_count).to eq("4") # 3 recent + 1 old
      end
    end
  end
end
