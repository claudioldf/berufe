# frozen_string_literal: true

class SearchEvent < ApplicationRecord
  MAXIMUM_RETAINED_QUERY_LENGTH = 80
  MAXIMUM_INPUT_PROMPT_LENGTH = 200
  AUDIT_STATUSES = %w[
    processing
    completed
    application_rate_limited
    provider_rate_limited
    provider_unavailable
    response_rejected
    search_failed
  ].freeze
  RESPONSE_SOURCES = %w[provider cache].freeze

  belongs_to :service, optional: true
  belongs_to :city, primary_key: :code, foreign_key: :city_code
  belongs_to :neighborhood,
    primary_key: :code,
    foreign_key: :neighborhood_code,
    optional: true

  validates :query_text_normalized,
    length: {maximum: MAXIMUM_RETAINED_QUERY_LENGTH},
    allow_nil: true
  validates :input_prompt,
    length: {maximum: MAXIMUM_INPUT_PROMPT_LENGTH},
    allow_nil: true
  validates :audit_status, inclusion: {in: AUDIT_STATUSES}, allow_nil: true
  validates :response_source, inclusion: {in: RESPONSE_SOURCES}, allow_nil: true
  validates :llm_prompt_digest,
    format: {with: /\A[0-9a-f]{64}\z/},
    allow_nil: true
  validates :result_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :profile_opened, :whatsapp_handoff_occurred, :reportable, inclusion: {in: [true, false]}
  validate :retained_query_is_normalized
  validate :audit_fields_require_prompt

  scope :reportable, -> { where(reportable: true) }
  scope :llm_audits, -> { where.not(input_prompt: nil) }

  private

  def retained_query_is_normalized
    return if query_text_normalized.nil?
    return if query_text_normalized.present? && PublicSearchText.normalize(query_text_normalized) == query_text_normalized

    errors.add(:query_text_normalized, :invalid)
  end

  def audit_fields_require_prompt
    return if input_prompt.present?

    fields = %i[
      raw_llm_response parsed_response response_source llm_adapter
      llm_model llm_provider_request_id llm_prompt_digest
    ]
    errors.add(:input_prompt, :blank) if fields.any? { |field| public_send(field).present? }
  end
end
