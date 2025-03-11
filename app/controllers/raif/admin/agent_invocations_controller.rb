# frozen_string_literal: true

module Raif
  module Admin
    class AgentInvocationsController < Raif::Admin::ApplicationController
      include Pagy::Backend

      def index
        @pagy, @agent_invocations = pagy(Raif::AgentInvocation.order(created_at: :desc))
      end

      def show
        @agent_invocation = Raif::AgentInvocation.find(params[:id])
      end
    end
  end
end
