# frozen_string_literal: true

class AddIdentityFieldsToProfessionalProfiles < ActiveRecord::Migration[8.1]
  def change
    change_table :professional_profiles, bulk: true do |table|
      table.text :headline
      table.text :bio
      table.integer :years_experience
      table.text :whatsapp_e164
      table.text :instagram_url
      table.text :youtube_url
    end

    add_check_constraint :professional_profiles,
      "headline IS NULL OR char_length(btrim(headline)) BETWEEN 1 AND 120",
      name: "professional_profiles_headline_length"
    add_check_constraint :professional_profiles,
      "bio IS NULL OR char_length(btrim(bio)) BETWEEN 1 AND 500",
      name: "professional_profiles_bio_length"
    add_check_constraint :professional_profiles,
      "years_experience IS NULL OR years_experience BETWEEN 0 AND 70",
      name: "professional_profiles_experience_range"
    add_check_constraint :professional_profiles,
      "whatsapp_e164 IS NULL OR whatsapp_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'",
      name: "professional_profiles_whatsapp_format"
    add_check_constraint :professional_profiles,
      "instagram_url IS NULL OR char_length(instagram_url) <= 200",
      name: "professional_profiles_instagram_length"
    add_check_constraint :professional_profiles,
      "youtube_url IS NULL OR char_length(youtube_url) <= 200",
      name: "professional_profiles_youtube_length"
  end
end
