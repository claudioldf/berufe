# frozen_string_literal: true

class AdminProfessionalSerializer
  def initialize(result)
    @result = result
  end

  def as_json(*)
    {
      items: result.professionals.map { |row| serialize_professional(row) },
      summary: result.summary,
      meta: {
        page: result.page,
        per_page: result.per_page,
        total_count: result.total_count,
        total_pages: result.total_pages
      }
    }
  end

  private

  attr_reader :result

  def serialize_professional(row)
    {
      id: row.id,
      professional_profile_id: row.professional_profile_id,
      public_slug: row.public_slug,
      display_name: row.display_name,
      profile_status: row.profile_status,
      city: row.city_name,
      state: row.state_abbreviation,
      phone_verified: row.phone_verified_at.present?,
      phone_last4: row.phone_e164&.last(4),
      identity_verified: row.identity_verified,
      account_status: row.account_status,
      impersonation_eligible: impersonation_eligible?(row),
      portfolio_count: row.portfolio_count,
      reference_count: row.reference_count,
      customer_count: row.customer_count,
      quote_count: row.quote_count,
      registered_at: row.registered_at&.iso8601,
      last_login_at: row.last_login_at&.iso8601,
      login_count: row.login_count,
      published_at: row.published_at&.iso8601
    }
  end

  def impersonation_eligible?(row)
    row.account_status == "active" &&
      row.registered_at.present? &&
      row.phone_verified_at.present? &&
      row.terms_accepted_at.present? &&
      row.terms_version == LegalDocumentVersions::TERMS &&
      row.privacy_notice_version == LegalDocumentVersions::PRIVACY_NOTICE &&
      row.professional_profile_id.present?
  end
end
