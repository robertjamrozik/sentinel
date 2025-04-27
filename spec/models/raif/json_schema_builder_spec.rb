# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::JsonSchemaBuilder do
  subject(:builder) { described_class.new }

  describe "#string" do
    it "adds a string property" do
      builder.string "name", description: "User name"
      schema = builder.to_schema

      expect(schema[:properties]["name"]).to include(
        type: "string",
        description: "User name"
      )
      expect(schema[:required]).to include("name")
    end
  end

  describe "#integer" do
    it "adds an integer property" do
      builder.integer "age", description: "User age", minimum: 18
      schema = builder.to_schema

      expect(schema[:properties]["age"]).to include(
        type: "integer",
        description: "User age",
        minimum: 18
      )
      expect(schema[:required]).to include("age")
    end
  end

  describe "#boolean" do
    it "adds a boolean property" do
      builder.boolean "active", description: "Is active"
      schema = builder.to_schema

      expect(schema[:properties]["active"]).to include(
        type: "boolean",
        description: "Is active"
      )
      expect(schema[:required]).to include("active")
    end
  end

  describe "#number" do
    it "adds a number property" do
      builder.number "price", description: "Product price", minimum: 0
      schema = builder.to_schema

      expect(schema[:properties]["price"]).to include(
        type: "number",
        description: "Product price",
        minimum: 0
      )
      expect(schema[:required]).to include("price")
    end
  end

  describe "#object" do
    it "adds a nested object property" do
      builder.object "profile", description: "User profile" do
        string "bio", description: "User biography"
      end
      schema = builder.to_schema

      # Check that the profile object is correctly defined
      expect(schema[:properties]["profile"]).to include(
        type: "object",
        description: "User profile"
      )

      # Check that the bio property is correctly defined in the nested object
      profile_props = schema[:properties]["profile"][:properties]
      expect(profile_props).to be_a(Hash)
      expect(profile_props["bio"]).to include(
        type: "string",
        description: "User biography"
      )

      # Verify that the profile object itself is required in the parent schema
      expect(schema[:required]).to include("profile")
    end
  end

  describe "#array" do
    it "adds an array property with object items" do
      builder.array "friends", description: "User friends" do
        object do
          string "name", description: "Friend name"
        end
      end
      schema = builder.to_schema

      expect(schema[:properties]["friends"]).to include(
        type: "array",
        description: "User friends"
      )
      expect(schema[:properties]["friends"][:items]).to include(
        type: "object"
      )
      expect(schema[:properties]["friends"][:items][:properties]["name"]).to include(
        type: "string",
        description: "Friend name"
      )
      expect(schema[:required]).to include("friends")
    end

    it "adds an array property with primitive items" do
      builder.array "tags", description: "User tags" do
        items type: "string"
      end
      schema = builder.to_schema

      expect(schema[:properties]["tags"]).to include(
        type: "array",
        description: "User tags",
        items: { type: "string" }
      )
      expect(schema[:required]).to include("tags")
    end
  end

  describe "#to_schema" do
    it "generates a valid JSON schema" do
      builder.string "name", description: "User name"
      builder.integer "age", description: "User age", minimum: 18
      builder.string "email", description: "User email", format: "email"

      schema = builder.to_schema

      expect(schema).to eq({
        type: "object",
        additionalProperties: false,
        properties: {
          "name" => { type: "string", description: "User name" },
          "age" => { type: "integer", description: "User age", minimum: 18 },
          "email" => { type: "string", description: "User email", format: "email" }
        },
        required: ["name", "age", "email"]
      })
    end
  end
end
