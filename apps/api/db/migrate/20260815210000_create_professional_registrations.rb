# frozen_string_literal: true

class CreateProfessionalRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :user_accounts, :terms_version, :text
    add_column :user_accounts, :privacy_notice_version, :text
    add_check_constraint :user_accounts,
      <<~SQL.squish,
        (terms_accepted_at IS NULL AND terms_version IS NULL AND privacy_notice_version IS NULL)
        OR
        (terms_accepted_at IS NOT NULL
          AND terms_version IS NOT NULL
          AND privacy_notice_version IS NOT NULL
          AND btrim(terms_version) <> ''
          AND btrim(privacy_notice_version) <> '')
      SQL
      name: "user_accounts_complete_legal_acceptance"

    create_table :professional_profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :user_account, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.text :display_name, null: false
      table.text :profile_status, null: false, default: "draft"
      table.timestamps null: false
    end

    add_index :professional_profiles, :profile_status
    add_check_constraint :professional_profiles,
      "char_length(btrim(display_name)) BETWEEN 3 AND 70",
      name: "professional_profiles_display_name_length"
    add_check_constraint :professional_profiles,
      "profile_status IN ('draft', 'pending_review', 'published', 'suspended')",
      name: "professional_profiles_known_status"
  end
end
