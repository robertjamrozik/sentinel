# frozen_string_literal: true

class AddCostColumnsToRaifModelCompletions < ActiveRecord::Migration[8.0]
  def change
    add_column :sentinel_model_completions, :prompt_token_cost, :decimal, precision: 10, scale: 6
    add_column :sentinel_model_completions, :output_token_cost, :decimal, precision: 10, scale: 6
    add_column :sentinel_model_completions, :total_cost, :decimal, precision: 10, scale: 6
  end
end
