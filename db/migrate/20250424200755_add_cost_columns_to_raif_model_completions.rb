# frozen_string_literal: true

class AddCostColumnsToRaifModelCompletions < ActiveRecord::Migration[8.0]
  # If you need to backfill cost columns for existing records:
  # Raif::ModelCompletion.find_each do |model_completion|
  #   model_completion.calculate_costs
  #   model_completion.save(validate: false)
  # end
  def change
    add_column :sentinel_model_completions, :prompt_token_cost, :decimal, precision: 10, scale: 6
    add_column :sentinel_model_completions, :output_token_cost, :decimal, precision: 10, scale: 6
    add_column :sentinel_model_completions, :total_cost, :decimal, precision: 10, scale: 6
  end
end
