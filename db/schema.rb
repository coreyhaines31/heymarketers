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

ActiveRecord::Schema[7.1].define(version: 2025_11_04_082559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.bigint "user_id"
    t.string "trackable_type", null: false
    t.bigint "trackable_id", null: false
    t.string "event_type", limit: 50, null: false
    t.json "properties", default: {}
    t.string "ip_address", limit: 45
    t.text "user_agent"
    t.string "session_id", limit: 128
    t.string "referrer", limit: 500
    t.string "utm_source", limit: 100
    t.string "utm_medium", limit: 100
    t.string "utm_campaign", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "event_type", "trackable_type"], name: "index_analytics_time_event_type"
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type", "created_at"], name: "index_analytics_events_on_event_type_and_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["session_id"], name: "index_analytics_events_on_session_id"
    t.index ["trackable_type", "trackable_id", "event_type"], name: "index_analytics_trackable_event"
    t.index ["trackable_type", "trackable_id"], name: "index_analytics_events_on_trackable"
    t.index ["trackable_type", "trackable_id"], name: "index_analytics_events_on_trackable_type_and_trackable_id"
    t.index ["user_id", "created_at"], name: "index_analytics_events_on_user_id_and_created_at"
    t.index ["user_id", "event_type"], name: "index_analytics_events_on_user_id_and_event_type"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
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
    t.string "company_size"
    t.index ["account_id"], name: "index_company_profiles_on_account_id"
    t.index ["company_size"], name: "index_company_profiles_on_company_size"
    t.index ["location_id"], name: "index_company_profiles_on_location_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "favoritable_type", null: false
    t.bigint "favoritable_id", null: false
    t.text "notes"
    t.boolean "private", default: true, null: false
    t.string "category", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_favorites_on_created_at"
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable"
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable_type_and_favoritable_id"
    t.index ["user_id", "category"], name: "index_favorites_on_user_id_and_category"
    t.index ["user_id", "created_at"], name: "index_favorites_on_user_id_and_created_at"
    t.index ["user_id", "favoritable_type", "favoritable_id"], name: "index_favorites_unique_user_favoritable", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
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
    t.tsvector "search_vector"
    t.string "external_source"
    t.string "external_id"
    t.string "external_url"
    t.string "external_guid"
    t.string "arrangement"
    t.string "location_type"
    t.text "location_limits"
    t.string "company_logo_url"
    t.string "application_url"
    t.string "salary_schedule"
    t.string "salary_currency"
    t.text "html_description"
    t.text "plain_text_description"
    t.datetime "last_synced_at"
    t.string "slug"
    t.index ["arrangement"], name: "index_job_listings_on_arrangement"
    t.index ["company_profile_id"], name: "index_job_listings_on_company_profile_id"
    t.index ["employment_type"], name: "index_job_listings_on_employment_type"
    t.index ["external_guid"], name: "index_job_listings_on_external_guid"
    t.index ["external_source", "external_id"], name: "index_job_listings_on_external_source_and_external_id", unique: true
    t.index ["last_synced_at"], name: "index_job_listings_on_last_synced_at"
    t.index ["location_id"], name: "index_job_listings_on_location_id"
    t.index ["location_type"], name: "index_job_listings_on_location_type"
    t.index ["posted_at"], name: "index_job_listings_on_posted_at"
    t.index ["remote_ok"], name: "index_job_listings_on_remote_ok"
    t.index ["salary_min", "salary_max"], name: "index_job_listings_on_salary_min_and_salary_max"
    t.index ["search_vector"], name: "index_job_listings_on_search_vector", using: :gin
    t.index ["slug"], name: "index_job_listings_on_slug"
  end

  create_table "job_sync_logs", force: :cascade do |t|
    t.string "source_type", null: false
    t.string "source_url", null: false
    t.integer "jobs_found", default: 0
    t.integer "jobs_created", default: 0
    t.integer "jobs_updated", default: 0
    t.integer "jobs_deleted", default: 0
    t.text "error_messages", default: [], array: true
    t.datetime "started_at"
    t.datetime "completed_at"
    t.boolean "success", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type"], name: "index_job_sync_logs_on_source_type"
    t.index ["started_at"], name: "index_job_sync_logs_on_started_at"
    t.index ["success"], name: "index_job_sync_logs_on_success"
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
    t.string "experience_level"
    t.tsvector "search_vector"
    t.string "resume_content_type"
    t.bigint "resume_file_size"
    t.datetime "resume_uploaded_at"
    t.boolean "profile_photo_processed", default: false
    t.text "cover_letter"
    t.text "portfolio_description"
    t.integer "portfolio_files_count", default: 0
    t.boolean "files_validated", default: false
    t.json "validation_errors", default: {}
    t.string "slug"
    t.index ["account_id"], name: "index_marketer_profiles_on_account_id"
    t.index ["availability"], name: "index_marketer_profiles_on_availability"
    t.index ["experience_level"], name: "index_marketer_profiles_on_experience_level"
    t.index ["files_validated"], name: "index_marketer_profiles_on_files_validated"
    t.index ["hourly_rate"], name: "index_marketer_profiles_on_hourly_rate"
    t.index ["location_id"], name: "index_marketer_profiles_on_location_id"
    t.index ["profile_photo_processed"], name: "index_marketer_profiles_on_profile_photo_processed"
    t.index ["resume_uploaded_at"], name: "index_marketer_profiles_on_resume_uploaded_at"
    t.index ["search_vector"], name: "index_marketer_profiles_on_search_vector", using: :gin
    t.index ["slug"], name: "index_marketer_profiles_on_slug", unique: true
  end

  create_table "marketer_skills", force: :cascade do |t|
    t.bigint "marketer_profile_id", null: false
    t.bigint "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marketer_profile_id"], name: "index_marketer_skills_on_marketer_profile_id"
    t.index ["skill_id"], name: "index_marketer_skills_on_skill_id"
  end

  create_table "marketer_tools", force: :cascade do |t|
    t.bigint "marketer_profile_id", null: false
    t.bigint "tool_id", null: false
    t.integer "proficiency_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marketer_profile_id"], name: "index_marketer_tools_on_marketer_profile_id"
    t.index ["tool_id"], name: "index_marketer_tools_on_tool_id"
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

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id"
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "notification_type", limit: 50, null: false
    t.string "title", limit: 255, null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.string "action_url", limit: 500
    t.json "metadata", default: {}
    t.boolean "email_sent", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "notification_type"], name: "index_notifications_on_recipient_id_and_notification_type"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["recipient_id"], name: "index_notifications_unread", where: "(read_at IS NULL)"
  end

  create_table "portfolio_files", force: :cascade do |t|
    t.bigint "marketer_profile_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.string "file_type", limit: 50, null: false
    t.bigint "file_size", null: false
    t.string "content_type", limit: 100, null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "is_public", default: true, null: false
    t.string "url", limit: 500
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_portfolio_files_on_created_at"
    t.index ["file_type"], name: "index_portfolio_files_on_file_type"
    t.index ["marketer_profile_id", "display_order"], name: "index_portfolio_files_on_marketer_profile_id_and_display_order"
    t.index ["marketer_profile_id", "display_order"], name: "index_portfolio_files_unique_order", unique: true
    t.index ["marketer_profile_id", "is_public"], name: "index_portfolio_files_on_marketer_profile_id_and_is_public"
    t.index ["marketer_profile_id"], name: "index_portfolio_files_on_marketer_profile_id"
  end

  create_table "review_helpful_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_review_helpful_votes_on_review_id"
    t.index ["user_id", "review_id"], name: "unique_user_review_vote", unique: true
    t.index ["user_id"], name: "index_review_helpful_votes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "reviewer_id", null: false
    t.bigint "reviewee_id", null: false
    t.bigint "marketer_profile_id", null: false
    t.integer "rating", null: false
    t.string "title", limit: 100, null: false
    t.text "content", null: false
    t.integer "helpful_count", default: 0, null: false
    t.string "status", default: "active", null: false
    t.boolean "anonymous", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["marketer_profile_id", "status"], name: "index_reviews_on_marketer_profile_id_and_status"
    t.index ["marketer_profile_id"], name: "index_reviews_on_marketer_profile_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["reviewee_id", "status"], name: "index_reviews_on_reviewee_id_and_status"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id", "marketer_profile_id"], name: "unique_reviewer_marketer_review", unique: true
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "rating_range_check"
    t.check_constraint "reviewer_id <> reviewee_id", name: "no_self_review_check"
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

  create_table "tools", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tools_on_slug", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analytics_events", "users"
  add_foreign_key "company_profiles", "accounts"
  add_foreign_key "company_profiles", "locations"
  add_foreign_key "favorites", "users"
  add_foreign_key "job_listings", "company_profiles"
  add_foreign_key "job_listings", "locations"
  add_foreign_key "marketer_profiles", "accounts"
  add_foreign_key "marketer_profiles", "locations"
  add_foreign_key "marketer_skills", "marketer_profiles"
  add_foreign_key "marketer_skills", "skills"
  add_foreign_key "marketer_tools", "marketer_profiles"
  add_foreign_key "marketer_tools", "tools"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "marketer_profiles"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "portfolio_files", "marketer_profiles"
  add_foreign_key "review_helpful_votes", "reviews"
  add_foreign_key "review_helpful_votes", "users"
  add_foreign_key "reviews", "marketer_profiles"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
end
