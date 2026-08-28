# frozen_string_literal: true

class ProfessionalProfileServiceArea < ApplicationRecord
  belongs_to :professional_profile_revision
  belongs_to :neighborhood, primary_key: :code, foreign_key: :neighborhood_code

  validates :neighborhood_code, uniqueness: {scope: :professional_profile_revision_id}
  validate :neighborhood_belongs_to_revision_city

  private

  def neighborhood_belongs_to_revision_city
    return if neighborhood.blank? || professional_profile_revision.blank?
    return if neighborhood.city_code == professional_profile_revision.coverage_city_code

    errors.add(:neighborhood, :invalid)
  end
end
