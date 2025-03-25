# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelTool, type: :model do
  describe "tool_arguments_schema" do
    it "returns the tool_arguments_schema" do
      expect(Raif::TestModelTool.tool_arguments_schema).to eq({
        type: "array",
        items: {
          type: "object",
          properties: {
            title: { type: "string" },
            description: { type: "string" },
          },
          required: ["title", "description"],
        },
      })
    end
  end
end
