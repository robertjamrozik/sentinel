# frozen_string_literal: true

module Raif
  class ApplicationJob < ::ApplicationJob
    include ActionView::RecordIdentifier

  end
end
