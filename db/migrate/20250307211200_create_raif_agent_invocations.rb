# frozen_string_literal: true

class CreateRaifAgentInvocations < ActiveRecord::Migration[8.0]
  def change
    create_table :sentinel_agent_invocations do |t|
      t.string :llm_model_name, null: false
      t.text :task
      t.text :system_prompt
      t.text :final_answer
      t.integer :max_iterations, default: 10, null: false
      t.integer :iteration_count, default: 0, null: false
      t.jsonb :available_model_tools
      t.references :creator, polymorphic: true, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :failure_reason
      t.jsonb :conversation_history, default: [], null: false

      t.timestamps
    end

    add_column :sentinel_completions, :sentinel_agent_invocation_id, :integer
    add_index :sentinel_completions, :sentinel_agent_invocation_id
  end
end
