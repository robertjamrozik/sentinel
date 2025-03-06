# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Completions", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }

  describe "index page" do
    let!(:completions) { FB.create_list(:sentinel_test_completion, 2, creator: creator) }
    let!(:completed_completion){ FB.create(:sentinel_test_completion, :completed, creator: creator) }
    let!(:failed_completion){ FB.create(:sentinel_test_completion, :failed, creator: creator) }
    let!(:in_progress_completion){ FB.create(:sentinel_test_completion, creator: creator, started_at: 1.minute.ago) }
    let!(:long_prompt_completion) do
      FB.create(:sentinel_test_completion, prompt: "a" * 200, creator: creator, prompt_tokens: 1000, completion_tokens: 500)
    end

    it "displays completions with all details, allows navigation, and handles edge cases" do
      visit sentinel.admin_completions_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("sentinel.admin.common.completions"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.id"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.created_at"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.creator"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.model"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.status"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.prompt_tokens"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.completion_tokens"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.prompt"))

      # Check completions count and status badges
      expect(page).to have_css("tr.sentinel-completion", count: 6) # Total number of completions
      expect(page).to have_css(".badge.bg-success", text: I18n.t("sentinel.admin.common.completed"))
      expect(page).to have_css(".badge.bg-danger", text: I18n.t("sentinel.admin.common.failed"))
      expect(page).to have_css(".badge.bg-warning", text: I18n.t("sentinel.admin.common.in_progress"))
      expect(page).to have_css(".badge.bg-secondary", text: I18n.t("sentinel.admin.common.pending"))

      # Check token counts
      within("table tbody") do
        expect(page).to have_content("1,000") # prompt_tokens
        expect(page).to have_content("500") # completion_tokens
      end

      # Truncated long prompt
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::Completion.delete_all
      visit sentinel.admin_completions_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.no_completions"))
    end
  end

  describe "show page" do
    let!(:completion) do
      FB.create(
        :sentinel_test_completion,
        :completed,
        creator: creator,
        prompt: "Test prompt",
        response: "Test response",
        system_prompt: "You are a test assistant",
        prompt_tokens: 10000,
        completion_tokens: 500,
        llm_model_name: "open_ai_gpt_4o_mini"
      )
    end

    before do
      visit sentinel.admin_completion_path(completion)
    end

    it "displays the completion details and has a back link to the completions index" do
      expect(page).to have_content(I18n.t("sentinel.admin.completions.show.title", id: completion.id))

      # Check basic details
      expect(page).to have_content(completion.id.to_s)
      expect(page).to have_content(completion.creator_type)
      expect(page).to have_content(completion.creator_id.to_s)
      expect(page).to have_content("open_ai_gpt_4o_mini")
      expect(page).to have_content(completion.response_format)

      # Check timestamps
      expect(page).to have_content(completion.created_at.strftime("%Y-%m-%d %H:%M:%S"))
      expect(page).to have_content(completion.started_at.strftime("%Y-%m-%d %H:%M:%S"))
      expect(page).to have_content(completion.completed_at.strftime("%Y-%m-%d %H:%M:%S"))

      # Check token counts
      expect(page).to have_content("10,000") # prompt_tokens
      expect(page).to have_content("500") # completion_tokens

      # Check prompt and response
      expect(page).to have_content("Test prompt")
      expect(page).to have_content("Test response")
      expect(page).to have_content("You are a test assistant")

      # Check back link functionality
      expect(page).to have_link(I18n.t("sentinel.admin.completions.show.back_to_completions"), href: sentinel.admin_completions_path)

      click_link I18n.t("sentinel.admin.completions.show.back_to_completions")
      expect(page).to have_current_path(sentinel.admin_completions_path)
    end
  end
end
