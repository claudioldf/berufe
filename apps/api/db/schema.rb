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

ActiveRecord::Schema[8.1].define(version: 2026_08_28_100000) do
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
    t.check_constraint "catalog_type = 'service'::text", name: "catalog_change_events_known_catalog_type"
    t.check_constraint "jsonb_typeof(change_data) = 'object'::text", name: "catalog_change_events_change_data_object"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "catalog_change_events_request_id_format"
    t.check_constraint "target_identifier <> ''::text", name: "catalog_change_events_target_present"
  end

  create_table "cities", primary_key: "code", id: :text, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.text "slug", null: false
    t.text "state_code", null: false
    t.datetime "updated_at", null: false
    t.index "state_code, lower(name)", name: "index_cities_on_state_and_name", unique: true
    t.index ["state_code", "slug"], name: "index_cities_on_state_code_and_slug", unique: true
    t.check_constraint "btrim(name) <> ''::text", name: "cities_name_present"
    t.check_constraint "code ~ '^[0-9]{7}$'::text", name: "cities_ibge_code_format"
    t.check_constraint "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "cities_slug_format"
  end

  create_table "customer_recommendation_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "email_fingerprint", limit: 64, null: false
    t.datetime "expires_at", null: false
    t.datetime "sent_at"
    t.uuid "service_job_id", null: false
    t.string "status", limit: 16, default: "open", null: false
    t.text "token_ciphertext"
    t.string "token_hash", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["service_job_id"], name: "idx_recommendation_requests_unique_job", unique: true
    t.index ["status", "expires_at"], name: "idx_recommendation_requests_status_expiry"
    t.index ["token_hash"], name: "idx_recommendation_requests_unique_token", unique: true
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying::text, 'completed'::character varying::text, 'expired'::character varying::text])", name: "customer_recommendation_requests_known_status"
  end

  create_table "customer_recommendations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.string "display_name", limit: 80, null: false
    t.string "email_fingerprint", limit: 64, null: false
    t.datetime "email_verified_at", null: false
    t.text "privacy_notice_version", null: false
    t.datetime "publication_authorized_at", null: false
    t.datetime "publication_withdrawn_at", precision: nil
    t.text "recommendation_text", null: false
    t.datetime "service_confirmed_at", null: false
    t.uuid "service_job_id", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_recommendations_on_customer_id"
    t.index ["publication_withdrawn_at"], name: "index_customer_recommendations_on_publication_withdrawn_at"
    t.index ["service_job_id"], name: "idx_customer_recommendations_unique_job", unique: true
    t.check_constraint "btrim(privacy_notice_version) <> ''::text", name: "customer_recommendations_privacy_version_present"
    t.check_constraint "char_length(btrim(display_name::text)) >= 1 AND char_length(btrim(display_name::text)) <= 80", name: "customer_recommendations_display_name_length"
    t.check_constraint "char_length(btrim(recommendation_text)) >= 1 AND char_length(btrim(recommendation_text)) <= 700", name: "customer_recommendations_text_length"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 254
    t.datetime "email_verified_at"
    t.string "name", limit: 80, null: false
    t.uuid "professional_id", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_e164", limit: 14, null: false
    t.index ["id", "professional_id"], name: "index_customers_on_id_and_professional", unique: true
    t.index ["professional_id", "name"], name: "index_customers_on_professional_and_name"
    t.index ["professional_id"], name: "index_customers_on_professional_id"
    t.check_constraint "char_length(btrim(name::text)) >= 1 AND char_length(btrim(name::text)) <= 80", name: "customers_name_length"
    t.check_constraint "whatsapp_e164::text ~ '^\\+55[1-9][0-9]9[0-9]{8}$'::text", name: "customers_brazilian_mobile"
  end

  create_table "data_erasure_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "failure_code", limit: 40
    t.datetime "requested_at", null: false
    t.datetime "retained_until", null: false
    t.string "status", limit: 16, default: "requested", null: false
    t.string "subject_digest", limit: 64, null: false
    t.uuid "target_user_account_id", null: false
    t.string "ticket_reference", limit: 100, null: false
    t.datetime "unpublished_at", null: false
    t.datetime "updated_at", null: false
    t.string "verification_method", limit: 32, null: false
    t.datetime "verified_at", null: false
    t.index ["retained_until"], name: "index_data_erasure_requests_on_retained_until"
    t.index ["subject_digest"], name: "index_data_erasure_requests_on_subject_digest"
    t.index ["target_user_account_id"], name: "idx_data_erasure_requests_one_active_account", unique: true, where: "((status)::text = ANY (ARRAY[('requested'::character varying)::text, ('processing'::character varying)::text, ('failed'::character varying)::text]))"
    t.check_constraint "status::text = ANY (ARRAY['requested'::character varying::text, 'processing'::character varying::text, 'failed'::character varying::text, 'completed'::character varying::text])", name: "data_erasure_requests_known_status"
    t.check_constraint "subject_digest::text ~ '^[0-9a-f]{64}$'::text", name: "data_erasure_requests_digest_format"
    t.check_constraint "ticket_reference::text ~ '^[A-Za-z0-9._/-]{1,100}$'::text", name: "data_erasure_requests_ticket_format"
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

  create_table "legal_retention_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.string "record_type", limit: 48, null: false
    t.datetime "retained_until", null: false
    t.string "subject_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["retained_until"], name: "index_legal_retention_records_on_retained_until"
    t.index ["subject_digest"], name: "index_legal_retention_records_on_subject_digest"
    t.check_constraint "jsonb_typeof(metadata) = 'object'::text", name: "legal_retention_records_metadata_object"
    t.check_constraint "subject_digest::text ~ '^[0-9a-f]{64}$'::text", name: "legal_retention_records_digest_format"
  end

  create_table "llm_search_analyses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "adapter", limit: 24, null: false
    t.integer "cache_hit_count", default: 0, null: false
    t.string "cache_key_digest", limit: 64, null: false
    t.integer "cached_input_tokens"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "expression_digest", limit: 64, null: false
    t.integer "input_tokens"
    t.integer "latency_ms"
    t.string "model", limit: 80, null: false
    t.integer "output_tokens"
    t.jsonb "parsed_result", null: false
    t.string "prompt_digest", limit: 64, null: false
    t.string "provider_request_id", limit: 120
    t.text "raw_response"
    t.datetime "updated_at", null: false
    t.index ["cache_key_digest"], name: "index_llm_search_analyses_on_cache_key_digest", unique: true
    t.index ["expires_at"], name: "index_llm_search_analyses_on_expires_at"
    t.check_constraint "cache_hit_count >= 0", name: "llm_search_analyses_nonnegative_hits"
    t.check_constraint "cache_key_digest::text ~ '^[0-9a-f]{64}$'::text", name: "llm_search_analyses_cache_digest_format"
    t.check_constraint "expression_digest::text ~ '^[0-9a-f]{64}$'::text", name: "llm_search_analyses_expression_digest_format"
    t.check_constraint "prompt_digest::text ~ '^[0-9a-f]{64}$'::text", name: "llm_search_analyses_prompt_digest_format"
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

  create_table "moderation_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action", null: false
    t.uuid "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.text "reason"
    t.text "request_id", null: false
    t.uuid "target_id", null: false
    t.text "target_type", null: false
    t.index ["admin_user_id", "created_at"], name: "index_moderation_actions_on_admin_user_id_and_created_at"
    t.index ["admin_user_id"], name: "index_moderation_actions_on_admin_user_id"
    t.index ["target_type", "target_id", "created_at"], name: "idx_moderation_actions_target_created"
    t.check_constraint "(action <> ALL (ARRAY['rejected'::text, 'hidden'::text])) OR reason IS NOT NULL AND char_length(btrim(reason)) >= 10 AND char_length(btrim(reason)) <= 500", name: "moderation_actions_required_reason"
    t.check_constraint "action = ANY (ARRAY['approved'::text, 'rejected'::text, 'hidden'::text, 'restored'::text])", name: "moderation_actions_known_action"
    t.check_constraint "note IS NULL OR char_length(btrim(note)) >= 1 AND char_length(btrim(note)) <= 500", name: "moderation_actions_note_length"
    t.check_constraint "reason IS NULL OR char_length(btrim(reason)) >= 1 AND char_length(btrim(reason)) <= 500", name: "moderation_actions_reason_length"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "moderation_actions_request_id_format"
    t.check_constraint "target_type = ANY (ARRAY['profile_revision'::text, 'profile_photo'::text, 'portfolio_item'::text, 'verification_request'::text])", name: "moderation_actions_known_target"
  end

  create_table "moderation_media_access_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.text "request_id", null: false
    t.uuid "target_id", null: false
    t.text "target_type", null: false
    t.index ["admin_user_id", "created_at"], name: "idx_moderation_media_access_admin_created"
    t.index ["admin_user_id"], name: "index_moderation_media_access_events_on_admin_user_id"
    t.index ["target_type", "target_id", "created_at"], name: "idx_moderation_media_access_target_created"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "moderation_media_access_request_id_format"
    t.check_constraint "target_type = ANY (ARRAY['profile_photo'::text, 'portfolio_item'::text])", name: "moderation_media_access_known_target"
  end

  create_table "neighborhoods", primary_key: "code", id: :text, force: :cascade do |t|
    t.text "city_code", null: false
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index "city_code, lower(name)", name: "index_neighborhoods_on_city_and_name"
    t.index ["city_code", "code"], name: "index_neighborhoods_on_city_code_and_code"
    t.check_constraint "btrim(name) <> ''::text", name: "neighborhoods_name_present"
    t.check_constraint "code ~ '^[0-9]{10}$'::text", name: "neighborhoods_ibge_code_format"
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

  create_table "professional_daily_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "activity_date", null: false
    t.datetime "created_at", null: false
    t.integer "evidence_creations", default: 0, null: false
    t.uuid "professional_id", null: false
    t.integer "profile_updates", default: 0, null: false
    t.integer "quotes_created", default: 0, null: false
    t.integer "relationship_interactions", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["activity_date", "professional_id"], name: "idx_professional_daily_activities_date_professional"
    t.index ["professional_id", "activity_date"], name: "idx_professional_daily_activities_professional_date", unique: true
    t.index ["professional_id"], name: "index_professional_daily_activities_on_professional_id"
    t.check_constraint "profile_updates >= 0 AND evidence_creations >= 0 AND relationship_interactions >= 0 AND quotes_created >= 0", name: "professional_daily_activities_nonnegative"
  end

  create_table "professional_daily_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "metric_date", null: false
    t.uuid "professional_id", null: false
    t.integer "profile_views", default: 0, null: false
    t.integer "quotes_shared", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "whatsapp_clicks", default: 0, null: false
    t.integer "whatsapp_clicks_public_profile", default: 0, null: false
    t.integer "whatsapp_clicks_search_result", default: 0, null: false
    t.index ["professional_id", "metric_date"], name: "index_professional_daily_metrics_on_professional_and_date", unique: true
    t.index ["professional_id"], name: "index_professional_daily_metrics_on_professional_id"
    t.check_constraint "profile_views >= 0 AND whatsapp_clicks >= 0 AND whatsapp_clicks_public_profile >= 0 AND whatsapp_clicks_search_result >= 0 AND quotes_shared >= 0", name: "professional_daily_metrics_nonnegative_counters"
    t.check_constraint "whatsapp_clicks = (whatsapp_clicks_public_profile + whatsapp_clicks_search_result)", name: "professional_daily_metrics_whatsapp_source_total"
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
    t.text "coverage_city_code"
    t.boolean "covers_whole_city", default: false, null: false
    t.datetime "created_at", null: false
    t.text "display_name", null: false
    t.text "headline"
    t.text "instagram_url"
    t.uuid "professional_profile_id", null: false
    t.text "profile_type", default: "self_service", null: false
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.text "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.text "whatsapp_e164"
    t.integer "years_experience"
    t.text "youtube_url"
    t.index ["coverage_city_code"], name: "index_professional_profile_revisions_on_coverage_city_code"
    t.index ["professional_profile_id", "profile_type"], name: "idx_profile_revisions_one_working_per_type", unique: true, where: "(status = ANY (ARRAY['draft'::text, 'pending_review'::text]))"
    t.index ["professional_profile_id", "version"], name: "idx_profile_revisions_unique_version", unique: true
    t.index ["professional_profile_id"], name: "idx_on_professional_profile_id_7926e53c9d"
    t.check_constraint "bio IS NULL OR char_length(btrim(bio)) >= 1 AND char_length(btrim(bio)) <= 2500", name: "professional_profile_revisions_bio_length"
    t.check_constraint "char_length(btrim(display_name)) >= 3 AND char_length(btrim(display_name)) <= 70", name: "professional_profile_revisions_display_name_length"
    t.check_constraint "headline IS NULL OR char_length(btrim(headline)) >= 1 AND char_length(btrim(headline)) <= 120", name: "professional_profile_revisions_headline_length"
    t.check_constraint "profile_type = ANY (ARRAY['self_service'::text, 'external'::text])", name: "professional_profile_revisions_known_profile_type"
    t.check_constraint "status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'approved'::text, 'rejected'::text, 'superseded'::text])", name: "professional_profile_revisions_known_status"
    t.check_constraint "whatsapp_e164 IS NULL OR whatsapp_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'::text", name: "professional_profile_revisions_whatsapp_format"
    t.check_constraint "years_experience IS NULL OR years_experience >= 0 AND years_experience <= 70", name: "professional_profile_revisions_experience_range"
  end

  create_table "professional_profile_service_areas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "neighborhood_code", null: false
    t.uuid "professional_profile_revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["neighborhood_code", "professional_profile_revision_id"], name: "idx_revision_service_areas_neighborhood_revision", where: "(neighborhood_code IS NOT NULL)"
    t.index ["professional_profile_revision_id", "neighborhood_code"], name: "idx_revision_service_areas_unique_neighborhood", unique: true
    t.index ["professional_profile_revision_id"], name: "idx_revision_service_areas_revision"
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
    t.index ["service_id", "professional_profile_revision_id"], name: "idx_revision_services_service_revision"
    t.index ["service_id"], name: "index_professional_profile_services_on_service_id"
    t.check_constraint "note IS NULL OR char_length(btrim(note)) >= 1 AND char_length(btrim(note)) <= 120", name: "professional_profile_services_note_length"
  end

  create_table "professional_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "approved_photo_id"
    t.uuid "approved_revision_id"
    t.date "birthdate"
    t.datetime "created_at", null: false
    t.text "creation_source", default: "self_service", null: false
    t.datetime "external_published_at"
    t.text "profile_status", default: "draft", null: false
    t.text "public_slug", null: false
    t.datetime "published_at"
    t.uuid "published_photo_id"
    t.uuid "published_revision_id"
    t.datetime "updated_at", null: false
    t.uuid "user_account_id", null: false
    t.uuid "working_photo_id"
    t.uuid "working_revision_id"
    t.index ["approved_photo_id"], name: "index_professional_profiles_on_approved_photo_id", unique: true
    t.index ["approved_revision_id"], name: "index_professional_profiles_on_approved_revision_id", unique: true
    t.index ["creation_source"], name: "index_professional_profiles_on_creation_source"
    t.index ["external_published_at"], name: "index_professional_profiles_on_external_published_at"
    t.index ["profile_status"], name: "index_professional_profiles_on_profile_status"
    t.index ["public_slug"], name: "index_professional_profiles_on_public_slug", unique: true
    t.index ["published_at"], name: "index_professional_profiles_on_published_at"
    t.index ["published_photo_id"], name: "index_professional_profiles_on_published_photo_id", unique: true
    t.index ["published_revision_id"], name: "index_professional_profiles_on_published_revision_id", unique: true
    t.index ["user_account_id"], name: "index_professional_profiles_on_user_account_id", unique: true
    t.index ["working_photo_id"], name: "index_professional_profiles_on_working_photo_id", unique: true
    t.index ["working_revision_id"], name: "index_professional_profiles_on_working_revision_id", unique: true
    t.check_constraint "creation_source = 'external'::text OR external_published_at IS NULL", name: "professional_profiles_external_publication_source"
    t.check_constraint "creation_source = ANY (ARRAY['self_service'::text, 'external'::text])", name: "professional_profiles_known_creation_source"
    t.check_constraint "profile_status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'published'::text, 'suspended'::text])", name: "professional_profiles_known_status"
    t.check_constraint "public_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text", name: "professional_profiles_public_slug_format"
  end

  create_table "professional_relationships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "contact_publication_attested_at"
    t.text "context_note"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.uuid "initiator_professional_id", null: false
    t.uuid "recipient_professional_id", null: false
    t.text "relationship_type", null: false
    t.datetime "responded_at"
    t.text "source", default: "existing_profile", null: false
    t.text "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_professional_id", "recipient_professional_id", "relationship_type"], name: "idx_professional_relationships_unique_direction", unique: true, where: "(deleted_at IS NULL)"
    t.index ["initiator_professional_id", "status"], name: "idx_professional_relationships_initiator_status"
    t.index ["initiator_professional_id"], name: "index_professional_relationships_on_initiator_professional_id"
    t.index ["recipient_professional_id", "status"], name: "idx_professional_relationships_recipient_status"
    t.index ["recipient_professional_id"], name: "index_professional_relationships_on_recipient_professional_id"
    t.index ["source"], name: "index_professional_relationships_on_source"
    t.check_constraint "context_note IS NULL OR char_length(btrim(context_note)) >= 1 AND char_length(btrim(context_note)) <= 300", name: "professional_relationships_context_length"
    t.check_constraint "initiator_professional_id <> recipient_professional_id", name: "professional_relationships_distinct_profiles"
    t.check_constraint "relationship_type = ANY (ARRAY['recommendation'::text, 'worked_together'::text])", name: "professional_relationships_known_type"
    t.check_constraint "source = 'existing_profile'::text OR contact_publication_attested_at IS NOT NULL", name: "professional_relationships_external_attestation"
    t.check_constraint "source = ANY (ARRAY['existing_profile'::text, 'external_phone'::text])", name: "professional_relationships_known_source"
    t.check_constraint "status = 'pending'::text AND responded_at IS NULL OR (status = ANY (ARRAY['accepted'::text, 'declined'::text])) AND responded_at IS NOT NULL", name: "professional_relationships_response_state"
    t.check_constraint "status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text])", name: "professional_relationships_known_status"
  end

  create_table "public_search_event_deduplications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "query_digest", limit: 64, null: false
    t.integer "result_count", null: false
    t.uuid "search_event_id", null: false
    t.string "subject_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_public_search_event_deduplications_on_expires_at"
    t.index ["subject_digest", "query_digest", "result_count"], name: "idx_public_search_event_deduplications_unique_claim", unique: true
    t.check_constraint "query_digest::text ~ '^[0-9a-f]{64}$'::text", name: "public_search_event_deduplications_query_digest_format"
    t.check_constraint "result_count >= 0", name: "public_search_event_deduplications_result_count_nonnegative"
    t.check_constraint "subject_digest::text ~ '^[0-9a-f]{64}$'::text", name: "public_search_event_deduplications_subject_digest_format"
  end

  create_table "public_search_rate_limit_counters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "request_count", default: 0, null: false
    t.string "subject_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.datetime "window_started_at", null: false
    t.index ["subject_digest", "window_started_at"], name: "idx_public_search_rate_limits_subject_window", unique: true
    t.index ["window_started_at"], name: "index_public_search_rate_limit_counters_on_window_started_at"
    t.check_constraint "request_count >= 0", name: "public_search_rate_limits_nonnegative_count"
    t.check_constraint "subject_digest::text ~ '^[0-9a-f]{64}$'::text", name: "public_search_rate_limits_digest_format"
  end

  create_table "quote_change_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.uuid "quote_id", null: false
    t.datetime "requested_at", null: false
    t.integer "requested_revision", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id", "requested_at", "id"], name: "index_quote_change_requests_on_quote_and_requested_at", order: { requested_at: :desc, id: :desc }
    t.index ["quote_id", "requested_revision"], name: "index_quote_change_requests_on_quote_and_revision", unique: true
    t.index ["quote_id"], name: "index_quote_change_requests_on_quote_id"
    t.check_constraint "char_length(btrim(message)) >= 1 AND char_length(btrim(message)) <= 700", name: "quote_change_requests_message_length"
    t.check_constraint "requested_revision >= 0", name: "quote_change_requests_nonnegative_revision"
  end

  create_table "quote_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "description", limit: 160, null: false
    t.decimal "line_total", precision: 14, scale: 2, null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.uuid "quote_id", null: false
    t.integer "sort_order", null: false
    t.string "unit", limit: 20, null: false
    t.decimal "unit_price", precision: 14, scale: 2, null: false
    t.index ["quote_id", "sort_order"], name: "index_quote_items_on_quote_id_and_sort_order", unique: true
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
    t.check_constraint "quantity > 0::numeric", name: "quote_items_positive_quantity"
    t.check_constraint "sort_order >= 0", name: "quote_items_nonnegative_sort_order"
    t.check_constraint "unit_price >= 0::numeric AND line_total >= 0::numeric", name: "quote_items_nonnegative_amounts"
  end

  create_table "quotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "customer_decided_at"
    t.text "customer_decision_message"
    t.string "customer_email", limit: 254
    t.uuid "customer_id", null: false
    t.string "customer_name", limit: 80, null: false
    t.string "customer_phone_e164", limit: 14, null: false
    t.decimal "discount_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "lock_version", default: 0, null: false
    t.text "notes"
    t.uuid "professional_id", null: false
    t.integer "quote_number", null: false
    t.date "scheduled_on"
    t.string "service_address", limit: 240
    t.string "service_description", limit: 160, null: false
    t.text "share_token_ciphertext"
    t.string "share_token_hash", limit: 64
    t.datetime "shared_at"
    t.string "status", limit: 16, default: "draft", null: false
    t.decimal "subtotal_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "terms_accepted_at"
    t.decimal "total_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.index ["customer_id", "professional_id"], name: "index_quotes_on_customer_and_professional"
    t.index ["customer_id"], name: "index_quotes_on_customer_id"
    t.index ["professional_id", "created_at", "id"], name: "index_quotes_on_professional_and_recent", order: { created_at: :desc, id: :desc }
    t.index ["professional_id", "quote_number"], name: "index_quotes_on_professional_id_and_quote_number", unique: true
    t.index ["professional_id"], name: "index_quotes_on_professional_id"
    t.index ["share_token_hash"], name: "index_quotes_on_share_token_hash", unique: true
    t.check_constraint "customer_decision_message IS NULL OR char_length(btrim(customer_decision_message)) >= 1 AND char_length(btrim(customer_decision_message)) <= 700", name: "quotes_customer_decision_message_length"
    t.check_constraint "customer_phone_e164::text ~ '^\\+55[1-9][0-9]9[0-9]{8}$'::text", name: "quotes_customer_brazilian_mobile"
    t.check_constraint "discount_amount <= subtotal_amount AND total_amount = (subtotal_amount - discount_amount)", name: "quotes_consistent_totals"
    t.check_constraint "quote_number > 0", name: "quotes_positive_number"
    t.check_constraint "status::text = 'draft'::text AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL OR status::text <> 'draft'::text AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL", name: "quotes_consistent_share_state"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'shared'::character varying::text, 'change_requested'::character varying::text, 'approved'::character varying::text, 'declined'::character varying::text])", name: "quotes_known_status"
    t.check_constraint "subtotal_amount >= 0::numeric AND discount_amount >= 0::numeric AND total_amount >= 0::numeric", name: "quotes_nonnegative_amounts"
  end

  create_table "search_daily_rollups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "city_code", null: false
    t.datetime "created_at", null: false
    t.text "neighborhood_code"
    t.date "report_date", null: false
    t.integer "searches", default: 0, null: false
    t.uuid "service_id"
    t.integer "thin_results", default: 0, null: false
    t.text "unmatched_query"
    t.datetime "updated_at", null: false
    t.integer "with_profile_open", default: 0, null: false
    t.integer "with_results", default: 0, null: false
    t.integer "with_three_results", default: 0, null: false
    t.integer "with_whatsapp_handoff", default: 0, null: false
    t.integer "zero_results", default: 0, null: false
    t.index ["city_code", "report_date"], name: "index_search_daily_rollups_on_city_code_and_report_date"
    t.index ["neighborhood_code", "report_date"], name: "idx_on_neighborhood_code_report_date_981793e93c"
    t.index ["report_date", "city_code", "service_id", "neighborhood_code", "unmatched_query"], name: "idx_search_daily_rollups_unique_dimensions", unique: true, nulls_not_distinct: true
    t.index ["service_id", "report_date"], name: "index_search_daily_rollups_on_service_id_and_report_date"
    t.index ["service_id"], name: "index_search_daily_rollups_on_service_id"
    t.check_constraint "searches >= 0 AND with_results >= 0 AND with_three_results >= 0 AND with_profile_open >= 0 AND with_whatsapp_handoff >= 0 AND zero_results >= 0 AND thin_results >= 0", name: "search_daily_rollups_nonnegative"
    t.check_constraint "service_id IS NULL OR unmatched_query IS NULL", name: "search_daily_rollups_do_not_mix_dimensions"
    t.check_constraint "unmatched_query IS NULL OR unmatched_query ~ '^[a-z0-9]+( [a-z0-9]+)*$'::text AND char_length(unmatched_query) <= 80", name: "search_daily_rollups_query_format"
    t.check_constraint "with_results <= searches AND with_three_results <= with_results AND with_profile_open <= searches AND with_whatsapp_handoff <= searches AND (zero_results + with_results) = searches AND thin_results <= with_results", name: "search_daily_rollups_subset_counts"
  end

  create_table "search_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "audit_status", limit: 32
    t.text "city_code", null: false
    t.datetime "created_at", null: false
    t.text "input_prompt"
    t.string "llm_adapter", limit: 24
    t.string "llm_model", limit: 80
    t.string "llm_prompt_digest", limit: 64
    t.string "llm_provider_request_id", limit: 120
    t.text "neighborhood_code"
    t.jsonb "parsed_response"
    t.boolean "profile_opened", default: false, null: false
    t.text "query_text_normalized"
    t.text "raw_llm_response"
    t.boolean "reportable", default: true, null: false
    t.string "response_source", limit: 16
    t.integer "result_count", null: false
    t.uuid "service_id"
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_handoff_occurred", default: false, null: false
    t.index ["city_code", "created_at"], name: "index_search_events_on_city_code_and_created_at"
    t.index ["created_at", "id"], name: "index_search_events_on_recent_llm_audits", order: :desc, where: "(input_prompt IS NOT NULL)"
    t.index ["created_at", "service_id", "neighborhood_code"], name: "index_search_events_on_time_service_and_neighborhood"
    t.index ["service_id"], name: "index_search_events_on_service_id"
    t.check_constraint "audit_status IS NULL OR (audit_status::text = ANY (ARRAY['processing'::character varying::text, 'completed'::character varying::text, 'application_rate_limited'::character varying::text, 'provider_rate_limited'::character varying::text, 'provider_unavailable'::character varying::text, 'response_rejected'::character varying::text, 'search_failed'::character varying::text]))", name: "search_events_known_audit_status"
    t.check_constraint "input_prompt IS NOT NULL OR raw_llm_response IS NULL AND parsed_response IS NULL AND response_source IS NULL AND llm_adapter IS NULL AND llm_model IS NULL AND llm_provider_request_id IS NULL AND llm_prompt_digest IS NULL", name: "search_events_audit_fields_require_prompt"
    t.check_constraint "input_prompt IS NULL OR char_length(input_prompt) >= 1 AND char_length(input_prompt) <= 200", name: "search_events_input_prompt_length"
    t.check_constraint "llm_prompt_digest IS NULL OR llm_prompt_digest::text ~ '^[0-9a-f]{64}$'::text", name: "search_events_llm_prompt_digest_format"
    t.check_constraint "query_text_normalized IS NULL OR query_text_normalized ~ '^[a-z0-9]+( [a-z0-9]+)*$'::text AND char_length(query_text_normalized) <= 80", name: "search_events_normalized_query_format"
    t.check_constraint "response_source IS NULL OR (response_source::text = ANY (ARRAY['provider'::character varying::text, 'cache'::character varying::text]))", name: "search_events_known_response_source"
    t.check_constraint "result_count >= 0", name: "search_events_result_count_nonnegative"
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

  create_table "service_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "completion_issue_at"
    t.text "completion_issue_message"
    t.datetime "completion_requested_at"
    t.datetime "created_at", null: false
    t.uuid "quote_id", null: false
    t.string "status", limit: 24, default: "approved", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_service_jobs_on_quote_id", unique: true
    t.index ["status", "updated_at"], name: "index_service_jobs_on_status_and_updated_at"
    t.check_constraint "cancellation_reason IS NULL OR char_length(btrim(cancellation_reason)) >= 1 AND char_length(btrim(cancellation_reason)) <= 700", name: "service_jobs_cancellation_reason_length"
    t.check_constraint "completion_issue_message IS NULL OR char_length(btrim(completion_issue_message)) >= 1 AND char_length(btrim(completion_issue_message)) <= 700", name: "service_jobs_completion_issue_message_length"
    t.check_constraint "status::text = ANY (ARRAY['approved'::character varying::text, 'completion_requested'::character varying::text, 'completion_issue'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text])", name: "service_jobs_known_status"
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

  create_table "states", primary_key: "code", id: :text, force: :cascade do |t|
    t.string "abbreviation", limit: 2, null: false
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "index_states_on_lower_name", unique: true
    t.index ["abbreviation"], name: "index_states_on_abbreviation", unique: true
    t.check_constraint "abbreviation::text ~ '^[A-Z]{2}$'::text", name: "states_abbreviation_format"
    t.check_constraint "btrim(name) <> ''::text", name: "states_name_present"
    t.check_constraint "code ~ '^[0-9]{2}$'::text", name: "states_ibge_code_format"
  end

  create_table "user_accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email"
    t.datetime "last_login_at"
    t.text "password_digest"
    t.text "phone_e164"
    t.datetime "phone_verified_at"
    t.text "privacy_notice_version"
    t.datetime "registered_at"
    t.text "role", default: "professional", null: false
    t.text "status", default: "active", null: false
    t.datetime "terms_accepted_at"
    t.text "terms_version"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_accounts_on_email", unique: true
    t.index ["phone_e164"], name: "index_user_accounts_on_phone_e164", unique: true
    t.index ["phone_verified_at"], name: "index_user_accounts_on_phone_verified_at"
    t.index ["registered_at"], name: "index_user_accounts_on_registered_at"
    t.index ["role", "status"], name: "index_user_accounts_on_role_and_status"
    t.check_constraint "email IS NULL OR email = lower(email) AND email = btrim(email)", name: "user_accounts_normalized_email"
    t.check_constraint "phone_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'::text", name: "user_accounts_brazilian_mobile_phone"
    t.check_constraint "registered_at IS NULL OR phone_verified_at IS NOT NULL", name: "user_accounts_registration_requires_verified_phone"
    t.check_constraint "role = 'professional'::text AND phone_e164 IS NOT NULL AND email IS NULL AND password_digest IS NULL OR role = 'admin'::text AND phone_e164 IS NULL AND email IS NOT NULL AND email <> ''::text AND password_digest IS NOT NULL AND password_digest <> ''::text", name: "user_accounts_role_credentials"
    t.check_constraint "role = ANY (ARRAY['professional'::text, 'admin'::text])", name: "user_accounts_known_role"
    t.check_constraint "status = ANY (ARRAY['active'::text, 'suspended'::text])", name: "user_accounts_known_status"
    t.check_constraint "terms_accepted_at IS NULL AND terms_version IS NULL AND privacy_notice_version IS NULL OR terms_accepted_at IS NOT NULL AND terms_version IS NOT NULL AND privacy_notice_version IS NOT NULL AND btrim(terms_version) <> ''::text AND btrim(privacy_notice_version) <> ''::text", name: "user_accounts_complete_legal_acceptance"
  end

  create_table "verification_file_access_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action", null: false
    t.uuid "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.text "request_id", null: false
    t.uuid "verification_file_id", null: false
    t.index ["admin_user_id", "created_at"], name: "idx_verification_file_access_admin_created"
    t.index ["admin_user_id"], name: "index_verification_file_access_events_on_admin_user_id"
    t.index ["verification_file_id", "created_at"], name: "idx_verification_file_access_target_created"
    t.index ["verification_file_id"], name: "index_verification_file_access_events_on_verification_file_id"
    t.check_constraint "action = 'viewed'::text", name: "verification_file_access_known_action"
    t.check_constraint "request_id ~ '^[A-Za-z0-9._-]{1,100}$'::text", name: "verification_file_access_request_id_format"
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
    t.date "claimed_birthdate"
    t.datetime "created_at", null: false
    t.datetime "expired_at"
    t.datetime "identity_match_confirmed_at"
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
  add_foreign_key "cities", "states", column: "state_code", primary_key: "code"
  add_foreign_key "customer_recommendation_requests", "service_jobs"
  add_foreign_key "customer_recommendations", "customers"
  add_foreign_key "customer_recommendations", "service_jobs"
  add_foreign_key "customers", "professional_profiles", column: "professional_id"
  add_foreign_key "media_uploads", "professional_profiles"
  add_foreign_key "moderation_actions", "user_accounts", column: "admin_user_id"
  add_foreign_key "moderation_media_access_events", "user_accounts", column: "admin_user_id"
  add_foreign_key "neighborhoods", "cities", column: "city_code", primary_key: "code"
  add_foreign_key "portfolio_items", "media_uploads"
  add_foreign_key "portfolio_items", "professional_profiles"
  add_foreign_key "portfolio_items", "services"
  add_foreign_key "professional_daily_activities", "professional_profiles", column: "professional_id"
  add_foreign_key "professional_daily_metrics", "professional_profiles", column: "professional_id"
  add_foreign_key "professional_profile_photos", "media_uploads"
  add_foreign_key "professional_profile_photos", "professional_profiles"
  add_foreign_key "professional_profile_revisions", "cities", column: "coverage_city_code", primary_key: "code"
  add_foreign_key "professional_profile_revisions", "professional_profiles"
  add_foreign_key "professional_profile_service_areas", "neighborhoods", column: "neighborhood_code", primary_key: "code"
  add_foreign_key "professional_profile_service_areas", "professional_profile_revisions"
  add_foreign_key "professional_profile_services", "professional_profile_revisions"
  add_foreign_key "professional_profile_services", "services"
  add_foreign_key "professional_profiles", "professional_profile_photos", column: "approved_photo_id"
  add_foreign_key "professional_profiles", "professional_profile_photos", column: "published_photo_id"
  add_foreign_key "professional_profiles", "professional_profile_photos", column: "working_photo_id"
  add_foreign_key "professional_profiles", "professional_profile_revisions", column: "approved_revision_id"
  add_foreign_key "professional_profiles", "professional_profile_revisions", column: "published_revision_id"
  add_foreign_key "professional_profiles", "professional_profile_revisions", column: "working_revision_id"
  add_foreign_key "professional_profiles", "user_accounts"
  add_foreign_key "professional_relationships", "professional_profiles", column: "initiator_professional_id"
  add_foreign_key "professional_relationships", "professional_profiles", column: "recipient_professional_id"
  add_foreign_key "public_search_event_deduplications", "search_events", on_delete: :cascade
  add_foreign_key "quote_change_requests", "quotes", on_delete: :cascade
  add_foreign_key "quote_items", "quotes", on_delete: :cascade
  add_foreign_key "quotes", "customers", column: ["customer_id", "professional_id"], primary_key: ["id", "professional_id"], name: "quotes_customer_owned_by_professional"
  add_foreign_key "quotes", "professional_profiles", column: "professional_id"
  add_foreign_key "search_daily_rollups", "cities", column: "city_code", primary_key: "code"
  add_foreign_key "search_daily_rollups", "neighborhoods", column: "neighborhood_code", primary_key: "code"
  add_foreign_key "search_daily_rollups", "services"
  add_foreign_key "search_events", "cities", column: "city_code", primary_key: "code"
  add_foreign_key "search_events", "neighborhoods", column: "neighborhood_code", primary_key: "code"
  add_foreign_key "search_events", "services"
  add_foreign_key "service_jobs", "quotes"
  add_foreign_key "services", "service_categories", column: "category_id"
  add_foreign_key "verification_file_access_events", "user_accounts", column: "admin_user_id"
  add_foreign_key "verification_file_access_events", "verification_files"
  add_foreign_key "verification_files", "media_uploads"
  add_foreign_key "verification_files", "verification_requests"
  add_foreign_key "verification_requests", "professional_profiles"
  add_foreign_key "verification_requests", "user_accounts", column: "reviewed_by_user_account_id"
end
