# frozen_string_literal: true

class Raif::UserToolInvocation < Raif::ApplicationRecord
  belongs_to :sentinel_conversation_entry, class_name: "Raif::ConversationEntry"

  attr_json_config default_container_attribute: :tool_settings

  delegate :tool_name, :tool_key, to: :class

  def message_input_placeholder
    I18n.t("#{self.class.name.underscore.gsub("/", ".")}.message_input_placeholder", default: nil)
  end

  def as_user_message
    # implement in subclasses
  end

  def self.tool_name
    I18n.t("#{name.underscore.gsub("/", ".")}.name")
  end

  def self.tool_key
    model_name.element
  end

  def self.tool_params
    []
  end
end
