# frozen_string_literal: true

module Raif
  module Admin
    class TasksController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @task_types = Raif::Task.distinct.pluck(:type)
        @selected_types = params[:task_types] || []

        tasks = Raif::Task.order(created_at: :desc)
        tasks = tasks.where(type: @selected_types) if @selected_types.present?

        @pagy, @tasks = pagy(tasks)
      end

      def show
        @task = Raif::Task.includes(:sentinel_model_completion).find(params[:id])
      end
    end
  end
end
