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

ActiveRecord::Schema[8.1].define(version: 2026_11_22_010000) do
  create_table "cryptics", force: :cascade do |t|
    t.string "external_id", null: false
    t.text "clue", null: false
    t.string "answer", null: false
    t.json "definitions", default: [], null: false
    t.json "indicators", default: [], null: false
    t.json "material", default: [], null: false
    t.string "puzzle_type", null: false
    t.string "difficulty", null: false
    t.text "hint"
    t.text "explanation"
    t.string "author"
    t.string "source", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deactivated_by_sync", default: false, null: false
    t.index ["external_id"], name: "index_cryptics_on_external_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "cryptic_id", null: false
    t.string "status", default: "PREPARED", null: false
    t.datetime "started_at"
    t.datetime "solved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cryptic_id"], name: "index_games_on_cryptic_id"
    t.index ["player_id", "cryptic_id"], name: "index_games_on_player_id_and_cryptic_id", unique: true
    t.index ["player_id"], name: "index_games_on_pending_player", unique: true, where: "status IN ('PREPARED', 'IN_PROGRESS')"
    t.index ["player_id"], name: "index_games_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_key", null: false
    t.string "token_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_key"], name: "index_players_on_name_key", unique: true
    t.index ["token_digest"], name: "index_players_on_token_digest", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.integer "user_id"
    t.string "source_url", null: false
    t.string "status", null: false
    t.string "version"
    t.integer "created_count", default: 0, null: false
    t.integer "updated_count", default: 0, null: false
    t.integer "deactivated_count", default: 0, null: false
    t.integer "rejected_count", default: 0, null: false
    t.json "rejections", default: [], null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "source_url"], name: "index_sync_runs_on_status_and_source_url"
    t.index ["user_id"], name: "index_sync_runs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "games", "cryptics"
  add_foreign_key "games", "players"
  add_foreign_key "sessions", "users"
  add_foreign_key "sync_runs", "users"
end
