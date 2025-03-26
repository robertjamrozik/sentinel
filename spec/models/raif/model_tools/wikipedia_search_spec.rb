# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelTools::WikipediaSearch do
  describe "#tool_arguments_schema" do
    it "validates against OpenAI's rules" do
      llm = Raif.llm(:open_ai_gpt_4o_mini)
      expect(llm.validate_json_schema!(described_class.tool_arguments_schema)).to eq(true)
    end
  end
end
