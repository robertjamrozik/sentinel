# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_24_234252) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "sentinel_completions", force: :cascade do |t|
    t.string "type", null: false
    t.text "prompt"
    t.text "response"
    t.integer "prompt_tokens", default: 0, null: false
    t.integer "completion_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.bigint "creator_id"
    t.string "creator_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "system_prompt"
    t.string "requested_language_key"
    t.integer "response_format", default: 0, null: false
    t.bigint "sentinel_conversation_entry_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.jsonb "available_model_tools"
    t.string "llm_model_name", null: false
    t.index ["sentinel_conversation_entry_id"], name: "index_sentinel_completions_on_sentinel_conversation_entry_id", unique: true
    t.index ["type"], name: "index_sentinel_completions_on_type"
  end

  create_table "sentinel_conversation_entries", force: :cascade do |t|
    t.bigint "sentinel_conversation_id", null: false
    t.bigint "creator_id"
    t.string "creator_type"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.text "user_message"
    t.text "model_response_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentinel_conversation_id"], name: "index_sentinel_conversation_entries_on_sentinel_conversation_id"
  end

  create_table "sentinel_conversations", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "creator_type"
    t.string "type"
    t.integer "conversation_entries_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sentinel_model_tool_invocations", force: :cascade do |t|
    t.bigint "sentinel_completion_id", null: false
    t.string "tool_type", null: false
    t.jsonb "tool_arguments", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentinel_completion_id"], name: "index_sentinel_model_tool_invocations_on_sentinel_completion_id"
  end

  create_table "sentinel_user_tool_invocations", force: :cascade do |t|
    t.bigint "sentinel_conversation_entry_id", null: false
    t.string "type", null: false
    t.jsonb "tool_settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentinel_conversation_entry_id"], name: "index_sentinel_user_tool_invocations_on_sentinel_conversation_entry_id"
  end
end
