# frozen_string_literal: true

module Raif
  module Admin
    module Stats
      class TasksController < Raif::Admin::ApplicationController
        def index
          @selected_period = params[:period] || "day"
          @time_range = get_time_range(@selected_period)

          @task_count = Raif::Task.where(created_at: @time_range).count
        end
      end
    end
  end
end
