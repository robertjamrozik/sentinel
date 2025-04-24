# frozen_string_literal: true

module Raif
  module Admin
    class StatsController < Raif::Admin::ApplicationController
      def index
        @selected_period = params[:period] || "day"
        @time_range = get_time_range(@selected_period)

        @model_completion_count = Raif::ModelCompletion.where(created_at: @time_range).count
        @model_completion_total_cost = Raif::ModelCompletion.where(created_at: @time_range).sum(:total_cost)
        @task_count = Raif::Task.where(created_at: @time_range).count
        @conversation_count = Raif::Conversation.where(created_at: @time_range).count
        @conversation_entry_count = Raif::ConversationEntry.where(created_at: @time_range).count
        @agent_count = Raif::Agent.where(created_at: @time_range).count
      end
    end
  end
end
