# frozen_string_literal: true

class CreateRaifTables < ActiveRecord::Migration[8.0]
  def change
    create_table :sentinel_completions do |t|
      t.string :type, null: false
      t.text :prompt
      t.text :response
      t.integer :prompt_tokens, default: 0, null: false
      t.integer :completion_tokens, default: 0, null: false
      t.integer :total_tokens, default: 0, null: false
      t.bigint :creator_id
      t.string :creator_type
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.text :system_prompt
      t.string :requested_language_key
      t.integer :response_format, default: 0, null: false
      t.bigint :sentinel_conversation_entry_id
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.jsonb :available_model_tools
      t.string :llm_model_name, null: false
    end

    add_index :sentinel_completions, :sentinel_conversation_entry_id, unique: true
    add_index :sentinel_completions, :type

    create_table :sentinel_conversation_entries do |t|
      t.bigint :sentinel_conversation_id, null: false
      t.bigint :creator_id
      t.string :creator_type
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :user_message
      t.text :model_response_message
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :sentinel_conversation_entries, :sentinel_conversation_id

    create_table :sentinel_conversations do |t|
      t.bigint :creator_id
      t.string :creator_type
      t.string :type
      t.integer :conversation_entries_count, default: 0, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :sentinel_model_tool_invocations do |t|
      t.bigint :sentinel_completion_id
      t.bigint :sentinel_agent_invocation_id
      t.string :tool_type, null: false
      t.jsonb :tool_arguments, default: {}, null: false
      t.jsonb :result, default: {}, null: false
      t.datetime :completed_at
      t.datetime :failed_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :sentinel_model_tool_invocations, :sentinel_completion_id
    add_index :sentinel_model_tool_invocations, :sentinel_agent_invocation_id

    create_table :sentinel_user_tool_invocations do |t|
      t.bigint :sentinel_conversation_entry_id, null: false
      t.string :type, null: false
      t.jsonb :tool_settings, default: {}, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :sentinel_user_tool_invocations, :sentinel_conversation_entry_id
  end
end
