# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ModelResponses", type: :feature do
  let(:user) { FB.create(:sentinel_test_user) }
  let(:completion) { FB.create(:sentinel_test_completion, creator: user) }
  let(:completion2) { FB.create(:sentinel_test_completion, creator: user) }
  let(:completion3) { FB.create(:sentinel_test_completion, creator: user) }
  let(:conversation) { FB.create(:sentinel_test_conversation, creator: user) }
  let(:conversation_entry) { FB.create(:sentinel_conversation_entry, sentinel_conversation: conversation, creator: user) }
  let(:agent_invocation) { FB.create(:sentinel_agent_invocation, creator: user) }

  describe "index page" do
    let!(:model_responses) do
      [
        Raif::ModelResponse.create!(
          source: agent_invocation,
          llm_model_key: "open_ai_gpt_4o_mini",
          response_format: "text",
          raw_response: "Test response 1",
          total_tokens: 1000
        ),
        Raif::ModelResponse.create!(
          source: conversation_entry,
          llm_model_key: "open_ai_gpt_4o",
          response_format: "text",
          raw_response: "Test response 2",
          total_tokens: 200
        )
      ]
    end

    let!(:json_response) do
      Raif::ModelResponse.create!(
        source: completion,
        llm_model_key: "open_ai_gpt_4o",
        response_format: "json",
        raw_response: '{"key": "value"}',
        prompt_tokens: 50,
        completion_tokens: 150,
        total_tokens: 200
      )
    end

    let!(:html_response) do
      Raif::ModelResponse.create!(
        source: completion2,
        llm_model_key: "bedrock_claude_3_5_sonnet",
        response_format: "html",
        raw_response: "<div>Test HTML</div>",
        prompt_tokens: 75,
        completion_tokens: 125,
        total_tokens: 200
      )
    end

    let!(:long_response) do
      Raif::ModelResponse.create!(
        source: completion3,
        llm_model_key: "open_ai_gpt_4o_mini",
        response_format: "text",
        raw_response: "a" * 200,
        total_tokens: 300
      )
    end

    it "displays model responses with all details and handles edge cases" do
      visit sentinel.admin_model_responses_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("sentinel.admin.common.model_responses"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.id"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.created_at"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.source"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.model"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.response_format"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.total_tokens"))
      expect(page).to have_content(I18n.t("sentinel.admin.common.response"))

      # Check model responses count and formats
      expect(page).to have_css("tr.sentinel-model-response", count: 5) # Total number of model responses
      expect(page).to have_content("text")
      expect(page).to have_content("json")
      expect(page).to have_content("html")

      # Check model names
      expect(page).to have_content("open_ai_gpt_4o_mini")
      expect(page).to have_content("open_ai_gpt_4o")
      expect(page).to have_content("bedrock_claude_3_5_sonnet")

      # Check token counts
      expect(page).to have_content("1,000")
      expect(page).to have_content("200")
      expect(page).to have_content("300")

      # Truncated long response
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::ModelResponse.delete_all
      visit sentinel.admin_model_responses_path
      expect(page).to have_content(I18n.t("sentinel.admin.common.no_model_responses"))
    end
  end

  describe "show page" do
    let!(:text_response) do
      Raif::ModelResponse.create!(
        source: completion,
        llm_model_key: "open_ai_gpt_4o_mini",
        response_format: "text",
        raw_response: "This is a test response",
        prompt_tokens: 25,
        completion_tokens: 75,
        total_tokens: 100
      )
    end

    it "displays the model response details and has a back link to the index" do
      visit sentinel.admin_model_response_path(text_response)

      expect(page).to have_content(I18n.t("sentinel.admin.model_responses.show.title", id: text_response.id))

      # Check basic details
      expect(page).to have_content(text_response.id.to_s)
      expect(page).to have_content(text_response.source_type)
      expect(page).to have_content(text_response.source_id.to_s)
      expect(page).to have_content("open_ai_gpt_4o_mini")
      expect(page).to have_content("text")

      # Check timestamps
      expect(page).to have_content(text_response.created_at.rfc822)

      # Check token counts
      expect(page).to have_content("25") # prompt_tokens
      expect(page).to have_content("75") # completion_tokens
      expect(page).to have_content("100") # total_tokens

      # Check response content
      expect(page).to have_content("This is a test response")

      # Check back link functionality
      expect(page).to have_link(I18n.t("sentinel.admin.model_responses.show.back_to_model_responses"), href: sentinel.admin_model_responses_path)

      click_link I18n.t("sentinel.admin.model_responses.show.back_to_model_responses")
      expect(page).to have_current_path(sentinel.admin_model_responses_path)
    end

    context "with JSON response format" do
      let!(:json_response) do
        Raif::ModelResponse.create!(
          source: completion,
          llm_model_key: "open_ai_gpt_4o",
          response_format: "json",
          raw_response: '{"key": "value", "nested": {"data": "test"}}',
          total_tokens: 150
        )
      end

      it "displays both raw and prettified JSON" do
        visit sentinel.admin_model_response_path(json_response)

        expect(page).to have_content(I18n.t("sentinel.admin.common.raw"))
        expect(page).to have_content('{"key": "value", "nested": {"data": "test"}}')

        expect(page).to have_content(I18n.t("sentinel.admin.common.prettified"))
        # The prettified JSON will have line breaks and indentation
        expect(page).to have_content('"key": "value"')
        expect(page).to have_content('"nested": {')
        expect(page).to have_content('"data": "test"')
      end
    end

    context "with HTML response format" do
      let!(:html_response) do
        Raif::ModelResponse.create!(
          source: completion2,
          llm_model_key: "bedrock_claude_3_5_sonnet",
          response_format: "html",
          raw_response: "<div><h1>Test</h1><p>HTML content</p></div>",
          total_tokens: 200
        )
      end

      it "displays both raw and rendered HTML" do
        visit sentinel.admin_model_response_path(html_response)

        expect(page).to have_content(I18n.t("sentinel.admin.common.raw"))
        expect(page).to have_content("<div><h1>Test</h1><p>HTML content</p></div>")

        expect(page).to have_content(I18n.t("sentinel.admin.common.rendered"))
        # The rendered HTML will be displayed in a div
        within(".border.p-3.bg-light") do
          expect(page).to have_css("h1", text: "Test")
          expect(page).to have_css("p", text: "HTML content")
        end
      end
    end
  end
end
