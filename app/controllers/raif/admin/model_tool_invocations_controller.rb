# frozen_string_literal: true

module Raif
  module Admin
    class ModelToolInvocationsController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @model_tool_invocations = pagy(Raif::ModelToolInvocation.order(created_at: :desc))
      end

      def show
        @model_tool_invocation = Raif::ModelToolInvocation.find(params[:id])
      end
    end
  end
end
