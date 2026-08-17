# frozen_string_literal: true

class CreateProfessionalProfileRevisions < ActiveRecord::Migration[8.1]
  REVISION_STATUSES = %w[draft pending_review approved rejected superseded].freeze

  def up
    add_column :professional_profiles, :public_slug, :text

    create_table :professional_profile_revisions, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.integer :version, null: false
      table.text :status, null: false, default: "draft"
      table.text :display_name, null: false
      table.text :headline
      table.text :bio
      table.integer :years_experience
      table.text :whatsapp_e164
      table.text :instagram_url
      table.text :youtube_url
      table.datetime :submitted_at
      table.datetime :reviewed_at
      table.text :rejection_reason
      table.timestamps null: false
    end

    add_index :professional_profile_revisions,
      %i[professional_profile_id version],
      unique: true,
      name: "idx_profile_revisions_unique_version"
    add_index :professional_profile_revisions,
      :professional_profile_id,
      unique: true,
      where: "status IN ('draft', 'pending_review')",
      name: "idx_profile_revisions_one_working"
    add_check_constraint :professional_profile_revisions,
      "status IN (#{REVISION_STATUSES.map { |status| quote(status) }.join(", ")})",
      name: "professional_profile_revisions_known_status"
    add_check_constraint :professional_profile_revisions,
      "char_length(btrim(display_name)) BETWEEN 3 AND 70",
      name: "professional_profile_revisions_display_name_length"
    add_check_constraint :professional_profile_revisions,
      "headline IS NULL OR char_length(btrim(headline)) BETWEEN 1 AND 120",
      name: "professional_profile_revisions_headline_length"
    add_check_constraint :professional_profile_revisions,
      "bio IS NULL OR char_length(btrim(bio)) BETWEEN 1 AND 500",
      name: "professional_profile_revisions_bio_length"
    add_check_constraint :professional_profile_revisions,
      "years_experience IS NULL OR years_experience BETWEEN 0 AND 70",
      name: "professional_profile_revisions_experience_range"
    add_check_constraint :professional_profile_revisions,
      "whatsapp_e164 IS NULL OR whatsapp_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'",
      name: "professional_profile_revisions_whatsapp_format"

    add_column :professional_profiles, :working_revision_id, :uuid
    add_column :professional_profiles, :published_revision_id, :uuid

    backfill_revisions!

    change_column_null :professional_profiles, :public_slug, false
    add_index :professional_profiles, :public_slug, unique: true
    add_check_constraint :professional_profiles,
      "public_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'",
      name: "professional_profiles_public_slug_format"
    add_foreign_key :professional_profiles,
      :professional_profile_revisions,
      column: :working_revision_id
    add_foreign_key :professional_profiles,
      :professional_profile_revisions,
      column: :published_revision_id
    add_index :professional_profiles, :working_revision_id, unique: true
    add_index :professional_profiles, :published_revision_id, unique: true

    move_supply_to_revisions!

    remove_check_constraint :professional_profiles, name: "professional_profiles_display_name_length"
    remove_check_constraint :professional_profiles, name: "professional_profiles_headline_length"
    remove_check_constraint :professional_profiles, name: "professional_profiles_bio_length"
    remove_check_constraint :professional_profiles, name: "professional_profiles_experience_range"
    remove_check_constraint :professional_profiles, name: "professional_profiles_whatsapp_format"
    remove_check_constraint :professional_profiles, name: "professional_profiles_instagram_length"
    remove_check_constraint :professional_profiles, name: "professional_profiles_youtube_length"
    remove_columns :professional_profiles,
      :display_name,
      :headline,
      :bio,
      :years_experience,
      :whatsapp_e164,
      :instagram_url,
      :youtube_url
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "profile revisions preserve moderation history"
  end

  private

  def backfill_revisions!
    used_slugs = Set.new
    select_all(<<~SQL.squish).each do |profile|
      SELECT id, display_name, headline, bio, years_experience, whatsapp_e164,
        instagram_url, youtube_url, profile_status, created_at, updated_at
      FROM professional_profiles
      ORDER BY created_at, id
    SQL
      slug = unique_slug(profile.fetch("display_name"), used_slugs)
      revision_id = SecureRandom.uuid
      revision_status = (profile.fetch("profile_status") == "published") ? "approved" : "draft"
      execute(<<~SQL.squish)
        INSERT INTO professional_profile_revisions (
          id, professional_profile_id, version, status, display_name, headline, bio,
          years_experience, whatsapp_e164, instagram_url, youtube_url, created_at, updated_at
        ) VALUES (
          #{quote(revision_id)}, #{quote(profile.fetch("id"))}, 1, #{quote(revision_status)},
          #{sql_value(profile.fetch("display_name"))}, #{sql_value(profile["headline"])}, #{sql_value(profile["bio"])},
          #{sql_value(profile["years_experience"])}, #{sql_value(profile["whatsapp_e164"])},
          #{sql_value(profile["instagram_url"])}, #{sql_value(profile["youtube_url"])},
          #{quote(profile.fetch("created_at"))}, #{quote(profile.fetch("updated_at"))}
        )
      SQL
      published_revision = (revision_status == "approved") ? revision_id : nil
      execute(<<~SQL.squish)
        UPDATE professional_profiles
        SET public_slug = #{quote(slug)},
          working_revision_id = #{quote(revision_id)},
          published_revision_id = #{sql_value(published_revision)}
        WHERE id = #{quote(profile.fetch("id"))}
      SQL
    end
  end

  def move_supply_to_revisions!
    add_column :professional_profile_services, :professional_profile_revision_id, :uuid
    add_column :professional_profile_service_areas, :professional_profile_revision_id, :uuid
    execute(<<~SQL.squish)
      UPDATE professional_profile_services AS selections
      SET professional_profile_revision_id = profiles.working_revision_id
      FROM professional_profiles AS profiles
      WHERE selections.professional_profile_id = profiles.id
    SQL
    execute(<<~SQL.squish)
      UPDATE professional_profile_service_areas AS areas
      SET professional_profile_revision_id = profiles.working_revision_id
      FROM professional_profiles AS profiles
      WHERE areas.professional_profile_id = profiles.id
    SQL
    change_column_null :professional_profile_services, :professional_profile_revision_id, false
    change_column_null :professional_profile_service_areas, :professional_profile_revision_id, false
    add_foreign_key :professional_profile_services,
      :professional_profile_revisions,
      column: :professional_profile_revision_id
    add_foreign_key :professional_profile_service_areas,
      :professional_profile_revisions,
      column: :professional_profile_revision_id

    remove_index :professional_profile_services, name: "idx_profile_services_unique_service"
    remove_index :professional_profile_services, name: "idx_profile_services_one_primary"
    remove_index :professional_profile_service_areas, name: "idx_profile_service_areas_profile"
    remove_index :professional_profile_service_areas, name: "idx_profile_service_areas_unique_neighborhood"
    remove_index :professional_profile_service_areas, name: "idx_profile_service_areas_unique_all_city"
    remove_reference :professional_profile_services, :professional_profile, foreign_key: true
    remove_reference :professional_profile_service_areas, :professional_profile, foreign_key: true

    add_index :professional_profile_services,
      %i[professional_profile_revision_id service_id],
      unique: true,
      name: "idx_revision_services_unique_service"
    add_index :professional_profile_services,
      :professional_profile_revision_id,
      unique: true,
      where: "is_primary",
      name: "idx_revision_services_one_primary"
    add_index :professional_profile_service_areas,
      :professional_profile_revision_id,
      name: "idx_revision_service_areas_revision"
    add_index :professional_profile_service_areas,
      %i[professional_profile_revision_id city_code neighborhood_code],
      unique: true,
      where: "neighborhood_code IS NOT NULL",
      name: "idx_revision_service_areas_unique_neighborhood"
    add_index :professional_profile_service_areas,
      %i[professional_profile_revision_id city_code],
      unique: true,
      where: "neighborhood_code IS NULL",
      name: "idx_revision_service_areas_unique_all_city"
  end

  def unique_slug(display_name, used_slugs)
    base = display_name.to_s.parameterize.presence || "profissional"
    candidate = base
    suffix = 2
    while used_slugs.include?(candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    used_slugs << candidate
    candidate
  end

  def sql_value(value)
    value.nil? ? "NULL" : quote(value)
  end
end
