# frozen_string_literal: true

module Raif
  module Admin
    class AgentsController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @agents = pagy(Raif::Agent.order(created_at: :desc))
      end

      def show
        @agent = Raif::Agent.find(params[:id])
      end
    end
  end
end
