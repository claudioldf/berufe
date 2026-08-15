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

ActiveRecord::Schema[8.1].define(version: 2026_08_15_183000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.datetime "discarded_at", precision: nil
    t.datetime "enqueued_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "jobs_finished_at", precision: nil
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at", precision: nil
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at", precision: nil
    t.jsonb "serialized_params"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "key"
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "cron_at", precision: nil
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at", precision: nil
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.integer "lock_type", limit: 2
    t.datetime "locked_at", precision: nil
    t.uuid "locked_by_id"
    t.datetime "performed_at", precision: nil
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at", precision: nil
    t.jsonb "serialized_params"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "neighborhoods", primary_key: "code", id: :text, force: :cascade do |t|
    t.text "city_code", null: false
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.text "name", null: false
    t.integer "sort_order", limit: 2, null: false
    t.string "state_code", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index "state_code, city_code, lower(name)", name: "index_active_neighborhoods_on_location_and_name", unique: true, where: "is_active"
    t.index ["sort_order", "code"], name: "index_neighborhoods_on_sort_order_and_code"
    t.check_constraint "btrim(name) <> ''::text", name: "neighborhoods_name_present"
    t.check_constraint "city_code = 'Joinville'::text", name: "neighborhoods_launch_city"
    t.check_constraint "code ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "neighborhoods_code_format"
    t.check_constraint "sort_order >= 0", name: "neighborhoods_sort_order_nonnegative"
    t.check_constraint "state_code::text = 'SC'::text", name: "neighborhoods_launch_state"
  end

  create_table "otp_challenges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.text "infobip_challenge_id_ciphertext", null: false
    t.text "phone_e164_ciphertext", null: false
    t.text "public_token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_otp_challenges_on_expires_at"
    t.index ["public_token_digest"], name: "index_otp_challenges_on_public_token_digest", unique: true
    t.check_constraint "btrim(infobip_challenge_id_ciphertext) <> ''::text", name: "otp_challenges_provider_ciphertext_present"
    t.check_constraint "btrim(phone_e164_ciphertext) <> ''::text", name: "otp_challenges_phone_ciphertext_present"
    t.check_constraint "btrim(public_token_digest) <> ''::text", name: "otp_challenges_public_token_digest_present"
    t.check_constraint "consumed_at IS NULL OR consumed_at >= created_at", name: "otp_challenges_consumed_after_creation"
    t.check_constraint "expires_at > created_at", name: "otp_challenges_expire_after_creation"
  end

  create_table "otp_request_counters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_requested_at"
    t.integer "request_count", limit: 2, default: 0, null: false
    t.text "scope_kind", null: false
    t.text "subject_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "window_started_at", null: false
    t.index ["expires_at"], name: "index_otp_request_counters_on_expires_at"
    t.index ["scope_kind", "subject_digest", "window_started_at"], name: "index_otp_counters_on_scope_subject_and_window", unique: true
    t.check_constraint "expires_at > window_started_at", name: "otp_request_counters_valid_window"
    t.check_constraint "last_requested_at IS NULL OR last_requested_at >= window_started_at", name: "otp_request_counters_request_inside_window"
    t.check_constraint "request_count >= 0", name: "otp_request_counters_nonnegative_count"
    t.check_constraint "scope_kind = ANY (ARRAY['phone'::text, 'ip'::text])", name: "otp_request_counters_known_scope"
    t.check_constraint "subject_digest ~ '^[0-9a-f]{64}$'::text", name: "otp_request_counters_digest_format"
  end

  create_table "service_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "icon", null: false
    t.boolean "is_active", default: true, null: false
    t.text "name", null: false
    t.text "slug", null: false
    t.integer "sort_order", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "index_active_service_categories_on_name", unique: true, where: "is_active"
    t.index ["slug"], name: "index_service_categories_on_slug", unique: true
    t.index ["sort_order", "slug"], name: "index_service_categories_on_sort_order_and_slug"
    t.check_constraint "btrim(name) <> ''::text", name: "service_categories_name_present"
    t.check_constraint "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "service_categories_slug_format"
    t.check_constraint "sort_order >= 0", name: "service_categories_sort_order_nonnegative"
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "aliases", default: [], null: false, array: true
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.text "icon", null: false
    t.boolean "is_active", default: true, null: false
    t.text "name", null: false
    t.text "slug", null: false
    t.integer "sort_order", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "sort_order", "slug"], name: "index_services_on_category_id_and_sort_order_and_slug"
    t.index ["category_id"], name: "index_services_on_category_id"
    t.index ["slug"], name: "index_services_on_slug", unique: true
    t.index ["sort_order", "slug"], name: "index_services_on_sort_order_and_slug"
    t.check_constraint "btrim(description) <> ''::text", name: "services_description_present"
    t.check_constraint "btrim(name) <> ''::text", name: "services_name_present"
    t.check_constraint "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "services_slug_format"
    t.check_constraint "sort_order >= 0", name: "services_sort_order_nonnegative"
  end

  add_foreign_key "services", "service_categories", column: "category_id"
end
