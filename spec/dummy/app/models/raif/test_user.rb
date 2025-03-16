# frozen_string_literal: true

class Raif::TestUser < ApplicationRecord
  def preferred_language_key
    # no-op so we can stub in tests
  end
end
