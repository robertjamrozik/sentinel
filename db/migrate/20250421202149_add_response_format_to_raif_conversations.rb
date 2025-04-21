# frozen_string_literal: true

class AddResponseFormatToRaifConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :sentinel_conversations, :response_format, :integer, default: 0, null: false
  end
end
