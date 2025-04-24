# frozen_string_literal: true

module Raif
  module Admin
    module Stats
      class TasksController < Raif::Admin::ApplicationController
        def index
          @selected_period = params[:period] || "day"
          @time_range = get_time_range(@selected_period)

          @task_count = Raif::Task.where(created_at: @time_range).count

          # Get task counts by type
          @task_counts_by_type = Raif::Task.where(created_at: @time_range).group(:type).count

          # Get costs by task type
          @task_costs_by_type = Raif::Task.joins(:sentinel_model_completion)
            .where(created_at: @time_range)
            .group(:type)
            .sum("sentinel_model_completions.total_cost")
        end
      end
    end
  end
end
