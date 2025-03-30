# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Agents::NativeToolCallingAgent, type: :model do
  let(:creator) { FB.create(:sentinel_test_user) }

  it_behaves_like "an agent"
end
