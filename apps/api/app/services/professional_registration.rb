# frozen_string_literal: true

class ProfessionalRegistration
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional registration")
    end
  end

  def call(user_account:, display_name:, accepted:, now: Time.current)
    validate_account!(user_account)
    normalized_name = display_name.to_s.squish
    validate_input!(display_name: normalized_name, accepted:)

    user_account.with_lock do
      if user_account.registration_completed?
        next user_account.professional_profile
      end

      profile = user_account.professional_profile || user_account.build_professional_profile
      profile.display_name = normalized_name
      profile.profile_status = "draft"
      profile.save!
      user_account.update!(
        terms_accepted_at: now,
        terms_version: LegalDocumentVersions::TERMS,
        privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
      )
      profile
    end
  end

  private

  def validate_account!(user_account)
    return if user_account.active? && user_account.professional?

    raise Invalid.new(base: ["Esta conta não pode concluir o cadastro profissional."])
  end

  def validate_input!(display_name:, accepted:)
    field_errors = {}
    field_errors[:display_name] = ["deve ter entre 3 e 70 caracteres"] unless display_name.length.between?(3, 70)
    field_errors[:accepted] = ["deve ser confirmado"] unless accepted == true
    raise Invalid.new(field_errors) if field_errors.any?
  end
end
