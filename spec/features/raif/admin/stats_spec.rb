# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Stats", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "index page" do
    let!(:model_completions) { FB.create_list(:sentinel_model_completion, 3, model_api_name: "gpt-4", created_at: 12.hours.ago) }
    let!(:tasks) { FB.create_list(:sentinel_test_task, 2, creator: creator, created_at: 12.hours.ago) }
    let!(:conversations) { FB.create_list(:sentinel_test_conversation, 2, creator: creator, created_at: 12.hours.ago) }

    let!(:conversation_entries) do
      conversations.flat_map do |conversation|
        FB.create_list(:sentinel_conversation_entry, 2, sentinel_conversation: conversation, creator: creator, created_at: 12.hours.ago)
      end
    end

    let!(:agents) { FB.create_list(:sentinel_native_tool_calling_agent, 1, created_at: 12.hours.ago) }

    # Create older records that shouldn't be counted in day period
    let!(:old_model_completion) { FB.create(:sentinel_model_completion, model_api_name: "gpt-4", created_at: 2.days.ago) }
    let!(:old_task) { FB.create(:sentinel_test_task, creator: creator, created_at: 2.days.ago) }
    let!(:old_conversation) { FB.create(:sentinel_test_conversation, creator: creator, created_at: 2.days.ago) }
    let!(:old_conversation_entry) do
      FB.create(:sentinel_conversation_entry, sentinel_conversation: old_conversation, creator: creator, created_at: 2.days.ago)
    end
    let!(:old_agent) { FB.create(:sentinel_native_tool_calling_agent, created_at: 2.days.ago) }

    it "displays stats dashboard with correct counts for differnt periods" do
      visit sentinel.admin_stats_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.stats"))

      # Check period filter has day selected by default
      expect(page).to have_select("period", selected: I18n.t("sentinel.admin.common.period_day"))

      # Model Completions
      within(".stats-card", text: I18n.t("sentinel.admin.common.model_completions")) do
        expect(page).to have_content("3") # Only the ones from last 24 hours
      end

      # Tasks
      within(".stats-card", text: I18n.t("sentinel.admin.common.tasks")) do
        expect(page).to have_content("2") # Only the ones from last 24 hours
        expect(page).to have_link(I18n.t("sentinel.admin.common.details"), href: sentinel.admin_stats_tasks_path(period: "day"))
      end

      # Conversations
      within(".stats-card", text: I18n.t("sentinel.admin.common.conversations")) do
        expect(page).to have_content("2") # Only the ones from last 24 hours
      end

      # Conversation Entries
      within(".stats-card", text: I18n.t("sentinel.admin.common.conversation_entries")) do
        expect(page).to have_content("4") # Only the ones from last 24 hours
      end

      # Agents
      within(".stats-card", text: I18n.t("sentinel.admin.common.agents")) do
        expect(page).to have_content("1") # Only the one from last 24 hours
      end

      # Change period to "all"
      select I18n.t("sentinel.admin.common.period_all"), from: "period"
      click_button I18n.t("sentinel.admin.common.update")

      # Expect counts to include all items
      within(".stats-card", text: I18n.t("sentinel.admin.common.model_completions")) do
        expect(page).to have_content("4") # 3 recent + 1 old
      end

      within(".stats-card", text: I18n.t("sentinel.admin.common.tasks")) do
        expect(page).to have_content("3") # 2 recent + 1 old
      end

      within(".stats-card", text: I18n.t("sentinel.admin.common.conversations")) do
        expect(page).to have_content("3") # 2 recent + 1 old
      end

      within(".stats-card", text: I18n.t("sentinel.admin.common.conversation_entries")) do
        expect(page).to have_content("5") # 4 recent + 1 old
      end

      within(".stats-card", text: I18n.t("sentinel.admin.common.agents")) do
        expect(page).to have_content("2") # 1 recent + 1 old
      end

      # Verify the "Details" link updates with the new period
      expect(page).to have_link(I18n.t("sentinel.admin.common.details"), href: sentinel.admin_stats_tasks_path(period: "all"))
    end
  end
end
