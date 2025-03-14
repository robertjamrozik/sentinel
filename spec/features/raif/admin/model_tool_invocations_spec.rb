# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ModelToolInvocations", type: :feature do
  let(:creator) { FB.create(:sentinel_test_user) }
  let(:task) { FB.create(:sentinel_test_task, creator: creator) }
  let(:conversation) { FB.create(:sentinel_test_conversation, creator: creator) }
  let(:conversation_entry) { FB.create(:sentinel_conversation_entry, sentinel_conversation: conversation, creator: creator) }
  let(:agent_invocation) { FB.create(:sentinel_agent_invocation, creator: creator) }

  describe "index page" do
    let!(:pending_tool_invocation) do
      Raif::ModelToolInvocation.create!(
        source: task,
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "Pending Tool", description: "This is a pending tool invocation" }]
      )
    end

    let!(:completed_tool_invocation) do
      invocation = Raif::ModelToolInvocation.create!(
        source: conversation_entry,
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "Completed Tool", description: "This is a completed tool invocation" }]
      )
      invocation.completed!
      invocation
    end

    let!(:failed_tool_invocation) do
      invocation = Raif::ModelToolInvocation.create!(
        source: agent_invocation,
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "Failed Tool", description: "This is a failed tool invocation" }]
      )
      invocation.failed!
      invocation
    end

    let!(:tool_invocation_with_result) do
      invocation = Raif::ModelToolInvocation.create!(
        source: task,
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "Tool with Result", description: "This tool has a result" }],
        result: { status: "success", data: "Some result data" }
      )
      invocation.completed!
      invocation
    end

    it "displays tool invocations with all details and handles empty state" do
      visit sentinel.admin_model_tool_invocations_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("sentinel.admin.common.model_tool_invocations"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.id"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.created_at"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.source"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.tool_type"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.status"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.tool_arguments"))

      # Check tool invocations count and status badges
      expect(page).to have_css("tr.sentinel-model-tool-invocation", count: 4) # Total number of tool invocations
      expect(page).to have_css(".badge.bg-success", text: I18n.t("sentinel.admin.common.completed"))
      expect(page).to have_css(".badge.bg-danger", text: I18n.t("sentinel.admin.common.failed"))
      expect(page).to have_css(".badge.bg-secondary", text: I18n.t("sentinel.admin.common.pending"))

      # Test navigation to tool invocation detail page
      click_link "##{completed_tool_invocation.id}"
      expect(page).to have_current_path(sentinel.admin_model_tool_invocation_path(completed_tool_invocation))

      # Go back to index and test empty state
      visit sentinel.admin_model_tool_invocations_path
      Raif::ModelToolInvocation.destroy_all
      visit sentinel.admin_model_tool_invocations_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.no_model_tool_invocations"))
    end
  end

  describe "show page" do
    let!(:tool_invocation) do
      invocation = Raif::ModelToolInvocation.create!(
        source: task,
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "Test Tool", description: "This is a test tool invocation" }],
        result: { status: "success", data: "Test result data" }
      )
      invocation.completed!
      invocation
    end

    it "displays the tool invocation details and has a back link to the index" do
      visit sentinel.admin_model_tool_invocation_path(tool_invocation)

      expect(page).to have_content(I18n.t("sentinel.admin.model_tool_invocations.show.title", id: tool_invocation.id))

      # Check basic details
      expect(page).to have_content(tool_invocation.id.to_s)
      expect(page).to have_content(tool_invocation.source_type)
      expect(page).to have_content(tool_invocation.source_id.to_s)
      expect(page).to have_content("TestModelTool")
      expect(page).to have_content("test_model")

      # Check timestamps
      expect(page).to have_content(tool_invocation.created_at.rfc822)
      expect(page).to have_content(tool_invocation.completed_at.rfc822)

      # Check status badge
      expect(page).to have_css(".badge.bg-success", text: I18n.t("sentinel.admin.common.completed"))

      # Check tool arguments and result
      expect(page).to have_content("Test Tool")
      expect(page).to have_content("This is a test tool invocation")
      expect(page).to have_content("success")
      expect(page).to have_content("Test result data")

      # Check back link functionality
      expect(page).to have_link(
        I18n.t("sentinel.admin.model_tool_invocations.show.back_to_model_tool_invocations"),
        href: sentinel.admin_model_tool_invocations_path
      )

      click_link I18n.t("sentinel.admin.model_tool_invocations.show.back_to_model_tool_invocations")
      expect(page).to have_current_path(sentinel.admin_model_tool_invocations_path)
    end

    context "with failed tool invocation" do
      let!(:failed_tool_invocation) do
        invocation = Raif::ModelToolInvocation.create!(
          source: task,
          tool_type: "Raif::TestModelTool",
          tool_arguments: [{ title: "Failed Tool", description: "This is a failed tool invocation" }]
        )
        invocation.failed!
        invocation
      end

      it "displays the failed status" do
        visit sentinel.admin_model_tool_invocation_path(failed_tool_invocation)

        expect(page).to have_css(".badge.bg-danger", text: I18n.t("sentinel.admin.common.failed"))
        expect(page).to have_content(failed_tool_invocation.failed_at.rfc822)
      end
    end

    context "with pending tool invocation" do
      let!(:pending_tool_invocation) do
        Raif::ModelToolInvocation.create!(
          source: task,
          tool_type: "Raif::TestModelTool",
          tool_arguments: [{ title: "Pending Tool", description: "This is a pending tool invocation" }]
        )
      end

      it "displays the pending status" do
        visit sentinel.admin_model_tool_invocation_path(pending_tool_invocation)

        expect(page).to have_css(".badge.bg-secondary", text: I18n.t("sentinel.admin.common.pending"))
      end
    end
  end
end
