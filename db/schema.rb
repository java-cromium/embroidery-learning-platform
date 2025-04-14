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

ActiveRecord::Schema[8.0].define(version: 2025_04_14_052600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_filter_presets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "resource_type", null: false
    t.json "filters", null: false
    t.boolean "global", default: false
    t.text "description"
    t.integer "usage_count", default: 0
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "global"], name: "index_admin_filter_presets_on_resource_type_and_global"
    t.index ["user_id", "resource_type", "name"], name: "idx_admin_filter_presets_composite", unique: true
    t.index ["user_id"], name: "index_admin_filter_presets_on_user_id"
  end

  create_table "admin_role_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "admin_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_role_id"], name: "index_admin_role_assignments_on_admin_role_id"
    t.index ["user_id", "admin_role_id"], name: "index_admin_role_assignments_on_user_id_and_admin_role_id", unique: true
    t.index ["user_id"], name: "index_admin_role_assignments_on_user_id"
  end

  create_table "admin_roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.jsonb "permissions", default: {}, null: false
    t.boolean "is_system_role", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_admin_roles_on_name", unique: true
  end

  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "difficulty_level"
    t.string "category"
    t.string "thumbnail_url"
    t.boolean "premium", default: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["premium"], name: "index_courses_on_premium"
  end

  create_table "embroidery_techniques", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "origin"
    t.text "instructions"
    t.string "difficulty_level"
    t.string "image_url"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "historical_artifacts", force: :cascade do |t|
    t.bigint "historical_period_id"
    t.string "name", null: false
    t.text "description"
    t.string "location"
    t.string "image_url"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["historical_period_id"], name: "index_historical_artifacts_on_historical_period_id"
  end

  create_table "historical_periods", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "era"
    t.integer "start_year"
    t.integer "end_year"
    t.string "region"
    t.string "image_url"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["era"], name: "index_historical_periods_on_era"
    t.index ["position"], name: "index_historical_periods_on_position"
    t.index ["region"], name: "index_historical_periods_on_region"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "video_url"
    t.string "thumbnail_url"
    t.integer "duration_seconds"
    t.integer "position"
    t.boolean "premium", default: false
    t.jsonb "materials", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_lessons_on_course_id_and_position"
    t.index ["course_id"], name: "index_lessons_on_course_id"
    t.index ["premium"], name: "index_lessons_on_premium"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_payment_method_id"
    t.string "card_brand"
    t.string "card_last4"
    t.integer "card_exp_month"
    t.integer "card_exp_year"
    t.boolean "default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "social_media_posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "platform", null: false
    t.string "external_id", null: false
    t.string "content_type"
    t.string "media_url"
    t.string "thumbnail_url"
    t.text "caption"
    t.string "permalink"
    t.datetime "posted_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform", "external_id"], name: "index_social_media_posts_on_platform_and_external_id", unique: true
    t.index ["posted_at"], name: "index_social_media_posts_on_posted_at"
    t.index ["user_id"], name: "index_social_media_posts_on_user_id"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.string "billing_interval", null: false
    t.jsonb "features", default: {}
    t.boolean "active", default: true
    t.string "stripe_price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.string "status", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "canceled_at"
    t.boolean "cancel_at_period_end", default: false
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "user_progress", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.float "progress_percentage", default: 0.0
    t.boolean "completed", default: false
    t.datetime "last_watched_at"
    t.integer "watch_time_seconds", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_user_progress_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_user_progress_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_user_progress_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.string "username"
    t.string "subscription_tier", default: "free"
    t.jsonb "social_profiles", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.boolean "premium", default: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "admin_filter_presets", "users"
  add_foreign_key "admin_role_assignments", "admin_roles"
  add_foreign_key "admin_role_assignments", "users"
  add_foreign_key "historical_artifacts", "historical_periods"
  add_foreign_key "lessons", "courses"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "social_media_posts", "users"
  add_foreign_key "subscriptions", "subscription_plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_progress", "lessons"
  add_foreign_key "user_progress", "users"
end
