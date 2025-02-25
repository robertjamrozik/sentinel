# frozen_string_literal: true

require_relative "concerns/boolean_timestamp"

require "attr_json"

class Raif::ApplicationRecord < ActiveRecord::Base
  include Raif::BooleanTimestamp
  include AttrJson::Record

  self.abstract_class = true

  scope :newest_first, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  def self.table_name_prefix
    "sentinel_"
  end
end
