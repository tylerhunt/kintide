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

ActiveRecord::Schema[8.1].define(version: 2026_07_15_195746) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "subscription_states", ["invited", "active", "deactivated"]

  create_table "accounts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.citext "email_address", null: false
    t.text "name", null: false
    t.text "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_accounts_on_email_address", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "circles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_circles_on_account_id", unique: true
  end

  create_table "posts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.text "body", null: false
    t.uuid "circle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["circle_id"], name: "index_posts_on_circle_id"
  end

  create_table "sessions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.text "ip_address"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["account_id"], name: "index_sessions_on_account_id"
  end

  create_table "shares", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.uuid "post_id", null: false
    t.uuid "subscription_id", null: false
    t.text "token", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "subscription_id"], name: "index_shares_on_post_id_and_subscription_id", unique: true
    t.index ["post_id"], name: "index_shares_on_post_id"
    t.index ["subscription_id"], name: "index_shares_on_subscription_id"
    t.index ["token"], name: "index_shares_on_token", unique: true
  end

  create_table "subscriptions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.datetime "accepted_at"
    t.uuid "circle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deactivated_at"
    t.text "name", null: false
    t.text "phone_number", null: false
    t.enum "state", default: "invited", null: false, enum_type: "subscription_states"
    t.text "token", null: false
    t.datetime "updated_at", null: false
    t.index ["circle_id", "phone_number"], name: "index_subscriptions_on_circle_id_and_phone_number", unique: true
    t.index ["circle_id"], name: "index_subscriptions_on_circle_id"
    t.index ["token"], name: "index_subscriptions_on_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "circles", "accounts"
  add_foreign_key "posts", "circles"
  add_foreign_key "sessions", "accounts"
  add_foreign_key "shares", "posts"
  add_foreign_key "shares", "subscriptions"
  add_foreign_key "subscriptions", "circles"
end
