# frozen_string_literal: true

module Raif
  module Admin
    class StatsController < Raif::Admin::ApplicationController
      def index
        @model_completion_count = Raif::ModelCompletion.count
        @task_count = Raif::Task.count
        @conversation_count = Raif::Conversation.count
        @conversation_entry_count = Raif::ConversationEntry.count
        @agent_count = Raif::Agent.count
      end
    end
  end
end
