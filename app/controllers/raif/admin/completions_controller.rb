# frozen_string_literal: true

module Raif
  module Admin
    class CompletionsController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @completions = pagy(Raif::Completion.order(created_at: :desc))
      end

      def show
        @completion = Raif::Completion.find(params[:id])
      end
    end
  end
end
