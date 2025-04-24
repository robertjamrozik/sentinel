# frozen_string_literal: true

class AddCreatedAtIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :sentinel_model_completions, :created_at
    add_index :sentinel_tasks, :created_at
    add_index :sentinel_conversations, :created_at
    add_index :sentinel_conversation_entries, :created_at
    add_index :sentinel_agents, :created_at
  end
end
