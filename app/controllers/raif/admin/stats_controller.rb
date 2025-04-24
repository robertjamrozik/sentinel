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

    private

      def get_time_range(period)
        case period
        when "day"
          24.hours.ago..Time.current
        when "week"
          1.week.ago..Time.current
        when "month"
          1.month.ago..Time.current
        when "all"
          Time.at(0)..Time.current
        else
          24.hours.ago..Time.current
        end
      end
    end
  end
end
