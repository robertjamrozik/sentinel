# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelToolInvocation, type: :model do
  describe "validations" do
    it "validates presence of tool_type" do
      invocation = described_class.new
      expect(invocation).not_to be_valid
      expect(invocation.errors[:tool_type]).to include("can't be blank")
    end

    it "validates tool_arguments against schema" do
      # Valid arguments
      invocation = described_class.new(
        source: FB.build(:sentinel_test_completion),
        tool_type: "Raif::TestModelTool",
        tool_arguments: [{ title: "foo", description: "bar" }]
      )
      expect(invocation).to be_valid

      # Invalid arguments
      invocation.tool_arguments = [{ foo: "bar" }]
      expect(invocation).not_to be_valid
      expect(invocation.errors[:tool_arguments]).to include("does not match schema")

      invocation.tool_arguments = [{ title: "foo" }]
      expect(invocation).not_to be_valid
      expect(invocation.errors[:tool_arguments]).to include("does not match schema")

      invocation.tool_arguments = { title: "foo", description: "bar" }
      expect(invocation).not_to be_valid
      expect(invocation.errors[:tool_arguments]).to include("does not match schema")
    end
  end
end
