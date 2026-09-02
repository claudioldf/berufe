# frozen_string_literal: true

class ProfessionalHeadlineBioGenerationJob < ApplicationJob
  queue_as :default

  retry_on ProfessionalHeadlineBioAiGenerator::ProviderUnavailable,
    wait: :polynomially_longer,
    attempts: 5

  def perform(revision_id, generator: ProfessionalHeadlineBioAiGenerator.new)
    revision = ProfessionalProfileRevision.find_by(id: revision_id)
    return unless revision
    return unless revision.headline.blank? || revision.bio.blank?

    generator.call(revision:)
  end
end
