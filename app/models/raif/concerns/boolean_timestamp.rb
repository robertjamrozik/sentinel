# frozen_string_literal: true

module Raif::Concerns::BooleanTimestamp
  extend ActiveSupport::Concern

  class_methods do
    # Column name should be something like email_abc_disabled_at, or its inverse should be specified
    def boolean_timestamp(column_name, define_inverse_accessors: false)
      if define_inverse_accessors.present?
        unless define_inverse_accessors.is_a?(Symbol) || column_name.end_with?("_disabled_at") || column_name.end_with?("_enabled_at")
          raise ArgumentError, "boolean_timestamp column name (#{column_name}) must end with '_disabled_at' or '_enabled_at'"
        end

        inverse_boolean_column_name = define_inverse_accessors if define_inverse_accessors.is_a?(Symbol)
      end

      # Get the boolean version of the column name (e.g. email_abc_disabled)
      boolean_column_name = column_name.to_s.gsub(/_at$/, "")

      # Define boolean getter (e.g. email_abc_disabled?)
      define_method("#{boolean_column_name}?") do
        send(column_name).present?
      end
      alias_method boolean_column_name, "#{boolean_column_name}?"

      # Define boolean setter (e.g. email_abc_disabled = true)
      define_method("#{boolean_column_name}=") do |val|
        if val == "1" || val == 1 || val == true || val == "true"
          send("#{column_name}=", Time.current) if send(column_name).nil?
        else
          send("#{column_name}=", nil)
        end
      end

      # Define bang method to set the value (e.g. email_abc_disabled!)
      define_method("#{boolean_column_name}!") do
        update(column_name => Time.current) if send(column_name).nil?
      end

      scope boolean_column_name, -> { where.not(table_name => { column_name => nil }) }

      # Define the inverse getter/setter (e.g. email_abc_enabled?)
      if define_inverse_accessors
        inverse_boolean_column_name ||= if boolean_column_name.end_with?("_disabled")
          boolean_column_name.gsub(/_disabled$/, "_enabled")
        else
          boolean_column_name.gsub(/_enabled$/, "_disabled")
        end

        # Define boolean getter (e.g. email_abc_enabled)
        define_method("#{inverse_boolean_column_name}?") do
          !send(boolean_column_name)
        end
        alias_method inverse_boolean_column_name, "#{inverse_boolean_column_name}?"

        # Define boolean setter (e.g. email_abc_enabled = true)
        define_method("#{inverse_boolean_column_name}=") do |val|
          if val == "1" || val == 1 || val == true || val == "true"
            send("#{column_name}=", nil)
          elsif send(column_name).nil?
            send("#{column_name}=", Time.current)
          end
        end

        scope inverse_boolean_column_name, -> { where(table_name => { column_name => nil }) }
      end
    end
  end
end
