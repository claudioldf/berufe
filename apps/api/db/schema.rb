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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_104000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "admin_access_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action", null: false
    t.uuid "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.text "operator_identifier", null: false
    t.text "request_id", null: false
    t.index ["admin_user_id", "created_at"], name: "index_admin_access_events_on_admin_user_id_and_created_at"
    t.index ["admin_user_id"], name: "index_admin_access_events_on_admin_user_id"
    t.check_constraint "action = ANY (ARRAY['provisioned'::text, 'password_reset'::text])", name: "admin_access_events_known_action"
    t.check_constraint "operator_identifier <> ''::text", name: "admin_access_events_operator_present"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "admin_access_events_request_id_format"
  end

  create_table "admin_login_attempt_counters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "scope", null: false
    t.text "subject_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "window_started_at", null: false
    t.index ["scope", "subject_digest", "window_started_at"], name: "index_admin_login_attempts_on_subject_and_window", unique: true
    t.check_constraint "attempt_count >= 0", name: "admin_login_attempt_counters_nonnegative_count"
    t.check_constraint "scope = ANY (ARRAY['email'::text, 'ip'::text])", name: "admin_login_attempt_counters_known_scope"
    t.check_constraint "subject_digest ~ '^[0-9a-f]{64}$'::text", name: "admin_login_attempt_counters_digest_format"
  end

  create_table "application_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "absolute_expires_at", null: false
    t.datetime "authenticated_at", null: false
    t.text "authentication_method", null: false
    t.datetime "created_at", null: false
    t.datetime "idle_expires_at", null: false
    t.datetime "last_active_at", null: false
    t.datetime "revoked_at"
    t.text "token_digest", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_account_id", null: false
    t.index ["absolute_expires_at"], name: "index_application_sessions_on_absolute_expires_at"
    t.index ["idle_expires_at"], name: "index_application_sessions_on_idle_expires_at"
    t.index ["token_digest"], name: "index_application_sessions_on_token_digest", unique: true
    t.index ["user_account_id", "created_at"], name: "index_application_sessions_on_user_account_id_and_created_at"
    t.index ["user_account_id"], name: "index_application_sessions_on_user_account_id"
    t.check_constraint "absolute_expires_at > authenticated_at", name: "application_sessions_absolute_after_authentication"
    t.check_constraint "authentication_method = ANY (ARRAY['sms_otp'::text, 'password'::text])", name: "application_sessions_known_authentication_method"
    t.check_constraint "idle_expires_at <= absolute_expires_at", name: "application_sessions_idle_within_absolute"
    t.check_constraint "idle_expires_at > last_active_at", name: "application_sessions_idle_after_activity"
    t.check_constraint "last_active_at >= authenticated_at", name: "application_sessions_activity_after_authentication"
    t.check_constraint "revoked_at IS NULL OR revoked_at >= authenticated_at", name: "application_sessions_revoked_after_authentication"
    t.check_constraint "token_digest ~ '^[0-9a-f]{64}$'::text", name: "application_sessions_token_digest_format"
  end

  create_table "catalog_change_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action", null: false
    t.uuid "admin_user_id", null: false
    t.text "catalog_type", null: false
    t.jsonb "change_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "request_id", null: false
    t.text "target_identifier", null: false
    t.index ["admin_user_id", "created_at"], name: "index_catalog_change_events_on_admin_user_id_and_created_at"
    t.index ["admin_user_id"], name: "index_catalog_change_events_on_admin_user_id"
    t.index ["catalog_type", "target_identifier", "created_at"], name: "index_catalog_changes_on_target_and_created_at"
    t.check_constraint "action = ANY (ARRAY['created'::text, 'updated'::text, 'activated'::text, 'deactivated'::text, 'reordered'::text])", name: "catalog_change_events_known_action"
    t.check_constraint "catalog_type = ANY (ARRAY['service'::text, 'neighborhood'::text])", name: "catalog_change_events_known_catalog_type"
    t.check_constraint "jsonb_typeof(change_data) = 'object'::text", name: "catalog_change_events_change_data_object"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "catalog_change_events_request_id_format"
    t.check_constraint "target_identifier <> ''::text", name: "catalog_change_events_target_present"
  end

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

  create_table "media_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "actual_byte_size"
    t.text "actual_content_type"
    t.datetime "attached_at"
    t.datetime "authorization_expires_at", null: false
    t.datetime "created_at", null: false
    t.bigint "declared_byte_size", null: false
    t.text "declared_content_type", null: false
    t.text "failure_code"
    t.integer "height"
    t.datetime "processed_at"
    t.integer "processing_attempts", default: 0, null: false
    t.datetime "processing_started_at"
    t.uuid "professional_profile_id", null: false
    t.text "purpose", null: false
    t.text "quarantine_key", null: false
    t.bigint "sanitized_byte_size"
    t.text "sanitized_content_type"
    t.text "sanitized_key"
    t.text "state", default: "authorized", null: false
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at"
    t.integer "width"
    t.index ["authorization_expires_at"], name: "idx_media_uploads_expiring_authorizations", where: "(state = 'authorized'::text)"
    t.index ["professional_profile_id", "purpose", "created_at"], name: "idx_on_professional_profile_id_purpose_created_at_8d91ce7f11"
    t.index ["professional_profile_id"], name: "index_media_uploads_on_professional_profile_id"
    t.index ["quarantine_key"], name: "index_media_uploads_on_quarantine_key", unique: true
    t.index ["sanitized_key"], name: "index_media_uploads_on_sanitized_key", unique: true, where: "(sanitized_key IS NOT NULL)"
    t.check_constraint "actual_byte_size IS NULL OR actual_byte_size >= 1 AND actual_byte_size <= 10485760", name: "media_uploads_actual_size_range"
    t.check_constraint "declared_byte_size >= 1 AND declared_byte_size <= 10485760", name: "media_uploads_declared_size_range"
    t.check_constraint "declared_content_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text])", name: "media_uploads_supported_declared_type"
    t.check_constraint "processing_attempts >= 0", name: "media_uploads_nonnegative_attempts"
    t.check_constraint "purpose = ANY (ARRAY['profile_photo'::text, 'portfolio_image'::text, 'verification_identity'::text])", name: "media_uploads_known_purpose"
    t.check_constraint "sanitized_content_type IS NULL OR (sanitized_content_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text]))", name: "media_uploads_supported_sanitized_type"
    t.check_constraint "state = ANY (ARRAY['authorized'::text, 'uploaded'::text, 'processing'::text, 'processed'::text, 'failed'::text, 'attached'::text, 'expired'::text])", name: "media_uploads_known_state"
    t.check_constraint "width IS NULL AND height IS NULL OR width > 0 AND height > 0", name: "media_uploads_valid_dimensions"
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
    t.check_constraint "char_length(city_code) <= 80", name: "neighborhoods_city_length"
    t.check_constraint "char_length(code) <= 80", name: "neighborhoods_code_length"
    t.check_constraint "char_length(name) <= 80", name: "neighborhoods_name_length"
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

  create_table "portfolio_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.text "content_type", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.integer "height", null: false
    t.datetime "hidden_at"
    t.uuid "media_upload_id", null: false
    t.text "private_key", null: false
    t.uuid "professional_profile_id", null: false
    t.text "public_key"
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.uuid "service_id", null: false
    t.text "status", default: "pending_review", null: false
    t.datetime "submitted_at", null: false
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.integer "width", null: false
    t.index ["media_upload_id"], name: "index_portfolio_items_on_media_upload_id", unique: true
    t.index ["private_key"], name: "index_portfolio_items_on_private_key", unique: true
    t.index ["professional_profile_id", "submitted_at", "id"], name: "idx_portfolio_items_owner_newest", order: { submitted_at: :desc, id: :desc }, where: "(deleted_at IS NULL)"
    t.index ["professional_profile_id"], name: "index_portfolio_items_on_professional_profile_id"
    t.index ["public_key"], name: "index_portfolio_items_on_public_key", unique: true, where: "(public_key IS NOT NULL)"
    t.index ["service_id"], name: "index_portfolio_items_on_service_id"
    t.check_constraint "byte_size > 0 AND width > 0 AND height > 0", name: "portfolio_items_valid_image"
    t.check_constraint "content_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text])", name: "portfolio_items_supported_content_type"
    t.check_constraint "status = ANY (ARRAY['pending_review'::text, 'approved'::text, 'rejected'::text, 'hidden'::text])", name: "portfolio_items_known_status"
  end

  create_table "professional_profile_photos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.text "content_type", default: "image/jpeg", null: false
    t.datetime "created_at", null: false
    t.integer "height", null: false
    t.datetime "hidden_at"
    t.uuid "media_upload_id", null: false
    t.text "private_key", null: false
    t.uuid "professional_profile_id", null: false
    t.text "public_key"
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.text "status", default: "pending_review", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.integer "width", null: false
    t.index ["media_upload_id"], name: "index_professional_profile_photos_on_media_upload_id", unique: true
    t.index ["private_key"], name: "index_professional_profile_photos_on_private_key", unique: true
    t.index ["professional_profile_id"], name: "idx_profile_photos_one_approved", unique: true, where: "(status = 'approved'::text)"
    t.index ["professional_profile_id"], name: "idx_profile_photos_one_pending", unique: true, where: "(status = 'pending_review'::text)"
    t.index ["professional_profile_id"], name: "index_professional_profile_photos_on_professional_profile_id"
    t.index ["public_key"], name: "index_professional_profile_photos_on_public_key", unique: true, where: "(public_key IS NOT NULL)"
    t.check_constraint "byte_size > 0 AND width >= 1 AND width <= 1024 AND height >= 1 AND height <= 1536", name: "professional_profile_photos_valid_variant"
    t.check_constraint "content_type = 'image/jpeg'::text", name: "professional_profile_photos_jpeg_only"
    t.check_constraint "status = ANY (ARRAY['pending_review'::text, 'approved'::text, 'rejected'::text, 'hidden'::text, 'superseded'::text])", name: "professional_profile_photos_known_status"
  end

  create_table "professional_profile_revisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.text "display_name", null: false
    t.text "headline"
    t.text "instagram_url"
    t.uuid "professional_profile_id", null: false
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.text "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.text "whatsapp_e164"
    t.integer "years_experience"
    t.text "youtube_url"
    t.index ["professional_profile_id", "version"], name: "idx_profile_revisions_unique_version", unique: true
    t.index ["professional_profile_id"], name: "idx_on_professional_profile_id_7926e53c9d"
    t.index ["professional_profile_id"], name: "idx_profile_revisions_one_working", unique: true, where: "(status = ANY (ARRAY['draft'::text, 'pending_review'::text]))"
    t.check_constraint "bio IS NULL OR char_length(btrim(bio)) >= 1 AND char_length(btrim(bio)) <= 500", name: "professional_profile_revisions_bio_length"
    t.check_constraint "char_length(btrim(display_name)) >= 3 AND char_length(btrim(display_name)) <= 70", name: "professional_profile_revisions_display_name_length"
    t.check_constraint "headline IS NULL OR char_length(btrim(headline)) >= 1 AND char_length(btrim(headline)) <= 120", name: "professional_profile_revisions_headline_length"
    t.check_constraint "status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'approved'::text, 'rejected'::text, 'superseded'::text])", name: "professional_profile_revisions_known_status"
    t.check_constraint "whatsapp_e164 IS NULL OR whatsapp_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'::text", name: "professional_profile_revisions_whatsapp_format"
    t.check_constraint "years_experience IS NULL OR years_experience >= 0 AND years_experience <= 70", name: "professional_profile_revisions_experience_range"
  end

  create_table "professional_profile_service_areas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "city_code", default: "Joinville", null: false
    t.datetime "created_at", null: false
    t.text "neighborhood_code"
    t.uuid "professional_profile_revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_profile_revision_id", "city_code", "neighborhood_code"], name: "idx_revision_service_areas_unique_neighborhood", unique: true, where: "(neighborhood_code IS NOT NULL)"
    t.index ["professional_profile_revision_id", "city_code"], name: "idx_revision_service_areas_unique_all_city", unique: true, where: "(neighborhood_code IS NULL)"
    t.index ["professional_profile_revision_id"], name: "idx_revision_service_areas_revision"
    t.check_constraint "city_code = 'Joinville'::text", name: "professional_profile_service_areas_joinville_only"
  end

  create_table "professional_profile_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false, null: false
    t.text "note"
    t.uuid "professional_profile_revision_id", null: false
    t.uuid "service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_profile_revision_id", "service_id"], name: "idx_revision_services_unique_service", unique: true
    t.index ["professional_profile_revision_id"], name: "idx_revision_services_one_primary", unique: true, where: "is_primary"
    t.index ["service_id"], name: "index_professional_profile_services_on_service_id"
    t.check_constraint "note IS NULL OR char_length(btrim(note)) >= 1 AND char_length(btrim(note)) <= 120", name: "professional_profile_services_note_length"
  end

  create_table "professional_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "profile_status", default: "draft", null: false
    t.text "public_slug", null: false
    t.uuid "published_photo_id"
    t.uuid "published_revision_id"
    t.datetime "updated_at", null: false
    t.uuid "user_account_id", null: false
    t.uuid "working_photo_id"
    t.uuid "working_revision_id"
    t.index ["profile_status"], name: "index_professional_profiles_on_profile_status"
    t.index ["public_slug"], name: "index_professional_profiles_on_public_slug", unique: true
    t.index ["published_photo_id"], name: "index_professional_profiles_on_published_photo_id", unique: true
    t.index ["published_revision_id"], name: "index_professional_profiles_on_published_revision_id", unique: true
    t.index ["user_account_id"], name: "index_professional_profiles_on_user_account_id", unique: true
    t.index ["working_photo_id"], name: "index_professional_profiles_on_working_photo_id", unique: true
    t.index ["working_revision_id"], name: "index_professional_profiles_on_working_revision_id", unique: true
    t.check_constraint "profile_status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'published'::text, 'suspended'::text])", name: "professional_profiles_known_status"
    t.check_constraint "public_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "professional_profiles_public_slug_format"
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
    t.check_constraint "char_length(description) <= 240", name: "services_description_length"
    t.check_constraint "char_length(name) <= 80", name: "services_name_length"
    t.check_constraint "char_length(slug) <= 80", name: "services_slug_length"
    t.check_constraint "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "services_slug_format"
    t.check_constraint "sort_order >= 0", name: "services_sort_order_nonnegative"
  end

  create_table "user_accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email"
    t.datetime "last_login_at"
    t.text "password_digest"
    t.text "phone_e164"
    t.text "privacy_notice_version"
    t.text "role", default: "professional", null: false
    t.text "status", default: "active", null: false
    t.datetime "terms_accepted_at"
    t.text "terms_version"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_accounts_on_email", unique: true
    t.index ["phone_e164"], name: "index_user_accounts_on_phone_e164", unique: true
    t.index ["role", "status"], name: "index_user_accounts_on_role_and_status"
    t.check_constraint "email IS NULL OR email = lower(email) AND email = btrim(email)", name: "user_accounts_normalized_email"
    t.check_constraint "phone_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'::text", name: "user_accounts_brazilian_mobile_phone"
    t.check_constraint "role = 'professional'::text AND phone_e164 IS NOT NULL AND email IS NULL AND password_digest IS NULL OR role = 'admin'::text AND phone_e164 IS NULL AND email IS NOT NULL AND email <> ''::text AND password_digest IS NOT NULL AND password_digest <> ''::text", name: "user_accounts_role_credentials"
    t.check_constraint "role = ANY (ARRAY['professional'::text, 'admin'::text])", name: "user_accounts_known_role"
    t.check_constraint "status = ANY (ARRAY['active'::text, 'suspended'::text])", name: "user_accounts_known_status"
    t.check_constraint "terms_accepted_at IS NULL AND terms_version IS NULL AND privacy_notice_version IS NULL OR terms_accepted_at IS NOT NULL AND terms_version IS NOT NULL AND privacy_notice_version IS NOT NULL AND btrim(terms_version) <> ''::text AND btrim(privacy_notice_version) <> ''::text", name: "user_accounts_complete_legal_acceptance"
  end

  create_table "verification_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.text "content_type", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "height", null: false
    t.uuid "media_upload_id", null: false
    t.text "private_key", null: false
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", null: false
    t.uuid "verification_request_id", null: false
    t.integer "width", null: false
    t.index ["media_upload_id"], name: "index_verification_files_on_media_upload_id", unique: true
    t.index ["private_key"], name: "index_verification_files_on_private_key", unique: true
    t.index ["verification_request_id"], name: "index_verification_files_on_verification_request_id", unique: true
    t.check_constraint "byte_size > 0 AND width > 0 AND height > 0", name: "verification_files_valid_image"
    t.check_constraint "content_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text])", name: "verification_files_supported_content_type"
  end

  create_table "verification_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "professional_profile_id", null: false
    t.text "public_label"
    t.text "review_note"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_user_account_id"
    t.text "status", default: "pending_review", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.text "verification_type", default: "identity", null: false
    t.datetime "verified_at"
    t.index ["professional_profile_id", "submitted_at", "id"], name: "idx_verification_requests_owner_newest", order: { submitted_at: :desc, id: :desc }
    t.index ["professional_profile_id", "verification_type"], name: "idx_verification_requests_one_pending_type", unique: true, where: "(status = 'pending_review'::text)"
    t.index ["professional_profile_id"], name: "index_verification_requests_on_professional_profile_id"
    t.index ["reviewed_by_user_account_id"], name: "index_verification_requests_on_reviewed_by_user_account_id"
    t.check_constraint "status = ANY (ARRAY['pending_review'::text, 'approved'::text, 'rejected'::text, 'expired'::text])", name: "verification_requests_known_status"
    t.check_constraint "verification_type = 'identity'::text", name: "verification_requests_identity_only"
  end

  add_foreign_key "admin_access_events", "user_accounts", column: "admin_user_id"
  add_foreign_key "application_sessions", "user_accounts"
  add_foreign_key "catalog_change_events", "user_accounts", column: "admin_user_id"
  add_foreign_key "media_uploads", "professional_profiles"
  add_foreign_key "portfolio_items", "media_uploads"
  add_foreign_key "portfolio_items", "professional_profiles"
  add_foreign_key "portfolio_items", "services"
  add_foreign_key "professional_profile_photos", "media_uploads"
  add_foreign_key "professional_profile_photos", "professional_profiles"
  add_foreign_key "professional_profile_revisions", "professional_profiles"
  add_foreign_key "professional_profile_service_areas", "neighborhoods", column: "neighborhood_code", primary_key: "code"
  add_foreign_key "professional_profile_service_areas", "professional_profile_revisions"
  add_foreign_key "professional_profile_services", "professional_profile_revisions"
  add_foreign_key "professional_profile_services", "services"
  add_foreign_key "professional_profiles", "professional_profile_photos", column: "published_photo_id"
  add_foreign_key "professional_profiles", "professional_profile_photos", column: "working_photo_id"
  add_foreign_key "professional_profiles", "professional_profile_revisions", column: "published_revision_id"
  add_foreign_key "professional_profiles", "professional_profile_revisions", column: "working_revision_id"
  add_foreign_key "professional_profiles", "user_accounts"
  add_foreign_key "services", "service_categories", column: "category_id"
  add_foreign_key "verification_files", "media_uploads"
  add_foreign_key "verification_files", "verification_requests"
  add_foreign_key "verification_requests", "professional_profiles"
  add_foreign_key "verification_requests", "user_accounts", column: "reviewed_by_user_account_id"
end
