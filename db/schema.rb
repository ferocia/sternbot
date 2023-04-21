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

ActiveRecord::Schema[7.0].define(version: 2023_04_21_175242) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "high_scores", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "value", null: false
    t.datetime "observed_at", null: false
    t.datetime "notified_at"
    t.bigint "players_id"
    t.index ["player_id"], name: "index_high_scores_on_player_id"
    t.index ["players_id"], name: "index_high_scores_on_players_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "tag"
    t.string "username"
  end

  add_foreign_key "high_scores", "players", column: "players_id"
end
