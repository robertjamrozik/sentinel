# frozen_string_literal: true

module Raif
  module Admin
    class ModelCompletionsController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @model_completions = pagy(Raif::ModelCompletion.order(created_at: :desc))
      end

      def show
        @model_completion = Raif::ModelCompletion.find(params[:id])
      end
    end
  end
end
