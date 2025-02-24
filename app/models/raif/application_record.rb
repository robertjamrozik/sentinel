# frozen_string_literal: true

require_relative "concerns/boolean_timestamp"

class Raif::ApplicationRecord < ActiveRecord::Base
  include Raif::BooleanTimestamp
  include AttrJson::Record

  self.abstract_class = true

  def self.table_name_prefix
    "sentinel_"
  end
end
