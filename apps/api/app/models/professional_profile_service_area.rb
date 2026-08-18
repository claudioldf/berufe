# frozen_string_literal: true

class ProfessionalProfileServiceArea < ApplicationRecord
  JOINVILLE = "Joinville"

  belongs_to :professional_profile_revision
  belongs_to :neighborhood, primary_key: :code, foreign_key: :neighborhood_code, optional: true

  validates :city_code, inclusion: {in: [JOINVILLE]}
  validates :neighborhood_code, uniqueness: {scope: %i[professional_profile_revision_id city_code]}, allow_nil: true
end
