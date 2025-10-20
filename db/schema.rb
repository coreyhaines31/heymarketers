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

ActiveRecord::Schema[7.1].define(version: 2025_10_20_044913) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "company_profiles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name"
    t.text "description"
    t.string "website"
    t.boolean "logo_attached"
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_company_profiles_on_account_id"
    t.index ["location_id"], name: "index_company_profiles_on_location_id"
  end

  create_table "job_listings", force: :cascade do |t|
    t.bigint "company_profile_id", null: false
    t.string "title"
    t.text "description"
    t.bigint "location_id"
    t.string "employment_type"
    t.integer "salary_min"
    t.integer "salary_max"
    t.boolean "remote_ok", default: false
    t.datetime "posted_at"
    t.datetime "expires_at"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_profile_id"], name: "index_job_listings_on_company_profile_id"
    t.index ["location_id"], name: "index_job_listings_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_locations_on_slug", unique: true
  end

  create_table "marketer_profiles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "title"
    t.text "bio"
    t.integer "hourly_rate"
    t.bigint "location_id", null: false
    t.string "availability"
    t.string "portfolio_url"
    t.boolean "resume_attached"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_marketer_profiles_on_account_id"
    t.index ["location_id"], name: "index_marketer_profiles_on_location_id"
  end

  create_table "marketer_skills", force: :cascade do |t|
    t.bigint "marketer_profile_id", null: false
    t.bigint "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marketer_profile_id"], name: "index_marketer_skills_on_marketer_profile_id"
    t.index ["skill_id"], name: "index_marketer_skills_on_skill_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_memberships_on_account_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "marketer_profile_id", null: false
    t.string "subject"
    t.text "body"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marketer_profile_id"], name: "index_messages_on_marketer_profile_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "service_types", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_service_types_on_slug", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_skills_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "company_profiles", "accounts"
  add_foreign_key "company_profiles", "locations"
  add_foreign_key "job_listings", "company_profiles"
  add_foreign_key "job_listings", "locations"
  add_foreign_key "marketer_profiles", "accounts"
  add_foreign_key "marketer_profiles", "locations"
  add_foreign_key "marketer_skills", "marketer_profiles"
  add_foreign_key "marketer_skills", "skills"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "marketer_profiles"
  add_foreign_key "messages", "users", column: "sender_id"
end
