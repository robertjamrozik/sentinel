# frozen_string_literal: true

module Raif
  module Admin
    class TasksController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @task_types = Raif::Task.distinct.pluck(:type)
        @selected_type = params[:task_types].present? ? params[:task_types] : "all"

        @task_statuses = [:all, :completed, :failed, :in_progress, :pending]
        @selected_statuses = params[:task_statuses].present? ? params[:task_statuses].to_sym : :all

        tasks = Raif::Task.order(created_at: :desc)
        tasks = tasks.where(type: @selected_type) if @selected_type.present? && @selected_type != "all"

        if @selected_statuses.present? && @selected_statuses != :all
          case @selected_statuses
          when :completed
            tasks = tasks.completed
          when :failed
            tasks = tasks.failed
          when :in_progress
            tasks = tasks.in_progress
          when :pending
            tasks = tasks.pending
          end
        end

        @pagy, @tasks = pagy(tasks)
      end

      def show
        @task = Raif::Task.includes(:sentinel_model_completion).find(params[:id])
      end
    end
  end
end
