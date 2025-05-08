# frozen_string_literal: true

class AddRetryCountToRaifModelCompletions < ActiveRecord::Migration[7.1]
  def change
    add_column :sentinel_model_completions, :retry_count, :integer, default: 0, null: false
  end
end
