# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ConversationEntryJob, type: :job do
  include ActiveJob::TestHelper
  include ActionView::RecordIdentifier

  let(:creator) { FB.create(:sentinel_test_user) }
  let(:conversation) { FB.create(:sentinel_conversation, creator: creator) }
  let(:conversation_entry) { FB.create(:sentinel_conversation_entry, sentinel_conversation: conversation, creator: creator) }

  describe "#perform" do
    it "processes the conversation entry" do
      expect(conversation_entry).to receive(:process_entry!).and_return(conversation_entry)
      expect(conversation_entry).to receive(:broadcast_replace_to).with(conversation)

      expect(Turbo::StreamsChannel).to receive(:broadcast_action_to).with(
        conversation,
        action: :sentinel_scroll_to_bottom,
        target: dom_id(conversation, :entries)
      )

      described_class.new.perform(conversation_entry: conversation_entry)
    end

    it "sets started_at timestamp before enqueuing" do
      expect do
        described_class.perform_later(conversation_entry: conversation_entry)
      end.to change { conversation_entry.reload.started_at }.from(nil).to(be_present)
    end

    context "when processing fails" do
      before do
        allow(conversation_entry).to receive(:process_entry!).and_raise(StandardError.new("Test error"))
      end

      it "handles the error" do
        described_class.new.perform(conversation_entry: conversation_entry)
        expect(conversation_entry.reload).to be_failed
      end
    end
  end
end
