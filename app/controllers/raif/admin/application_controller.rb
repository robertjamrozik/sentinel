# frozen_string_literal: true

module Raif
  module Admin
    class ApplicationController < Raif::ApplicationController
      include Pagy::Backend

      layout "sentinel/admin"

    private

      def authorize_sentinel_action
        unless instance_exec(&Raif.config.authorize_admin_controller_action)
          raise Raif::Errors::ActionNotAuthorizedError, "Admin action not authorized"
        end
      end

      def get_time_range(period)
        case period
        when "day"
          24.hours.ago..Time.current
        when "week"
          1.week.ago..Time.current
        when "month"
          1.month.ago..Time.current
        when "all"
          Time.at(0)..Time.current
        else
          24.hours.ago..Time.current
        end
      end
    end
  end
end
