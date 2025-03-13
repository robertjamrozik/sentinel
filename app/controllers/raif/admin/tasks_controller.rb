# frozen_string_literal: true

module Raif
  module Admin
    class TasksController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @tasks = pagy(Raif::Task.order(created_at: :desc))
      end

      def show
        @task = Raif::Task.includes(:sentinel_model_completion).find(params[:id])
      end
    end
  end
end
