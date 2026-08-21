# frozen_string_literal: true

class AddExternalProfessionalProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :user_accounts, :phone_verified_at, :datetime
    add_column :user_accounts, :registered_at, :datetime
    add_check_constraint :user_accounts,
      "registered_at IS NULL OR phone_verified_at IS NOT NULL",
      name: "user_accounts_registration_requires_verified_phone"
    add_index :user_accounts, :registered_at
    add_index :user_accounts, :phone_verified_at

    add_column :professional_profiles, :creation_source, :text, null: false, default: "self_service"
    add_column :professional_profiles, :external_published_at, :datetime
    add_check_constraint :professional_profiles,
      "creation_source IN ('self_service', 'external')",
      name: "professional_profiles_known_creation_source"
    add_check_constraint :professional_profiles,
      "creation_source = 'external' OR external_published_at IS NULL",
      name: "professional_profiles_external_publication_source"
    add_index :professional_profiles, :creation_source
    add_index :professional_profiles, :external_published_at

    add_column :professional_profile_revisions, :profile_type, :text, null: false, default: "self_service"
    add_check_constraint :professional_profile_revisions,
      "profile_type IN ('self_service', 'external')",
      name: "professional_profile_revisions_known_profile_type"
    remove_index :professional_profile_revisions, name: "idx_profile_revisions_one_working"
    add_index :professional_profile_revisions,
      %i[professional_profile_id profile_type],
      unique: true,
      where: "status IN ('draft', 'pending_review')",
      name: "idx_profile_revisions_one_working_per_type"

    add_column :professional_relationships, :source, :text, null: false, default: "existing_profile"
    add_column :professional_relationships, :contact_publication_attested_at, :datetime
    add_check_constraint :professional_relationships,
      "source IN ('existing_profile', 'external_phone')",
      name: "professional_relationships_known_source"
    add_check_constraint :professional_relationships,
      "source = 'existing_profile' OR contact_publication_attested_at IS NOT NULL",
      name: "professional_relationships_external_attestation"
    add_index :professional_relationships, :source

    execute <<~SQL.squish
      UPDATE user_accounts
      SET phone_verified_at = created_at
      WHERE role = 'professional'
    SQL
    execute <<~SQL.squish
      UPDATE user_accounts
      SET registered_at = terms_accepted_at
      WHERE role = 'professional' AND terms_accepted_at IS NOT NULL
    SQL
  end

  def down
    remove_index :professional_relationships, :source
    remove_check_constraint :professional_relationships, name: "professional_relationships_external_attestation"
    remove_check_constraint :professional_relationships, name: "professional_relationships_known_source"
    remove_columns :professional_relationships, :source, :contact_publication_attested_at

    remove_index :professional_profile_revisions, name: "idx_profile_revisions_one_working_per_type"
    add_index :professional_profile_revisions,
      :professional_profile_id,
      unique: true,
      where: "status IN ('draft', 'pending_review')",
      name: "idx_profile_revisions_one_working"
    remove_check_constraint :professional_profile_revisions,
      name: "professional_profile_revisions_known_profile_type"
    remove_column :professional_profile_revisions, :profile_type

    remove_index :professional_profiles, :external_published_at
    remove_index :professional_profiles, :creation_source
    remove_check_constraint :professional_profiles, name: "professional_profiles_external_publication_source"
    remove_check_constraint :professional_profiles, name: "professional_profiles_known_creation_source"
    remove_columns :professional_profiles, :creation_source, :external_published_at

    remove_index :user_accounts, :phone_verified_at
    remove_index :user_accounts, :registered_at
    remove_check_constraint :user_accounts, name: "user_accounts_registration_requires_verified_phone"
    remove_columns :user_accounts, :phone_verified_at, :registered_at
  end
end
