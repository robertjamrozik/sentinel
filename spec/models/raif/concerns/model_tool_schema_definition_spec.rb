# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Concerns::JsonSchemaDefinition do
  describe "Raif::TestModelTool.tool_arguments_schema" do
    it "generates the correct schema" do
      expect(Raif::TestModelTool.tool_arguments_schema).to eq({
        type: "object",
        additionalProperties: false,
        required: ["items"],
        properties: {
          items: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              properties: {
                title: { type: "string", description: "The title of the item" },
                description: { type: "string" },
              },
              required: ["title", "description"],
            }
          }
        }
      })
    end
  end

  describe "Raif::ModelTools::ComplexTestTool.tool_arguments_schema" do
    it "generates the correct schema" do
      expect(Raif::ModelTools::ComplexTestTool.tool_arguments_schema).to eq({
        type: "object",
        properties: {
          title: {
            type: "string",
            description: "The title of the operation",
            minLength: 3
          },
          settings: {
            type: "object",
            description: "Configuration settings",
            properties: {
              enabled: {
                type: "boolean",
                description: "Whether the tool is enabled"
              },
              priority: {
                type: "integer",
                description: "Priority level (1-10)",
                minimum: 1,
                maximum: 10
              },
              tags: {
                type: "array",
                description: "Associated tags",
                items: {
                  type: "string"
                }
              }
            },
            required: ["enabled", "priority", "tags"],
            additionalProperties: false
          },
          products: {
            type: "array",
            description: "List of products",
            items: {
              type: "object",
              properties: {
                id: {
                  type: "integer",
                  description: "Product identifier"
                },
                name: {
                  type: "string",
                  description: "Product name"
                },
                price: {
                  type: "number",
                  description: "Product price",
                  minimum: 0
                }
              },
              required: ["id", "name", "price"],
              additionalProperties: false
            }
          }
        },
        required: ["title", "settings", "products"],
        additionalProperties: false
      })
    end
  end
end
