# frozen_string_literal: true

class AddStatusIndexesToRaifTasks < ActiveRecord::Migration[8.0]
  def change
    add_index :sentinel_tasks, :completed_at
    add_index :sentinel_tasks, :failed_at
    add_index :sentinel_tasks, :started_at

    # Index for type + status combinations which will be common in the admin interface
    add_index :sentinel_tasks, [:type, :completed_at]
    add_index :sentinel_tasks, [:type, :failed_at]
    add_index :sentinel_tasks, [:type, :started_at]
  end
end
