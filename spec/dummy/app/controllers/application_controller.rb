# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Used by Raif to get the current user
  def current_user
    @current_user ||= Raif::TestUser.find_or_create_by(email: "test@example.com")
  end
end
