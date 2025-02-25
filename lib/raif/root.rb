# frozen_string_literal: true

module Raif

  def self.root
    @root ||= Pathname.new(File.expand_path("../..", __dir__))
  end

end
