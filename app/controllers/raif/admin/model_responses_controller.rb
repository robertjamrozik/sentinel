# frozen_string_literal: true

module Raif
  module Admin
    class ModelResponsesController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @model_responses = pagy(Raif::ModelResponse.order(created_at: :desc))
      end

      def show
        @model_response = Raif::ModelResponse.find(params[:id])
      end
    end
  end
end
