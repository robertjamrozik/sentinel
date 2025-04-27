# frozen_string_literal: true

module Raif
  module Concerns
    module JsonSchemaDefinition
      extend ActiveSupport::Concern

      class_methods do
        def json_schema_definition(schema_name, &block)
          raise ArgumentError, "A block must be provided to define the JSON schema" unless block_given?

          @schemas ||= {}
          @schemas[schema_name] = Raif::JsonSchemaBuilder.new
          @schemas[schema_name].instance_eval(&block)
          @schemas[schema_name]
        end

        def schema_defined?(schema_name)
          @schemas&.dig(schema_name).present?
        end

        def schema_for(schema_name)
          @schemas[schema_name].to_schema
        end
      end
    end
  end
end
