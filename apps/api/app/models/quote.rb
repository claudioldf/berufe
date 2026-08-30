# frozen_string_literal: true

class Quote < ApplicationRecord
  STATUSES = %w[draft saved shared change_requested approved declined].freeze
  MAX_ITEMS = 20
  MONEY_SCALE = 2

  belongs_to :professional, class_name: "ProfessionalProfile", inverse_of: :quotes
  belongs_to :customer, inverse_of: :quotes, optional: true
  has_one :service_job, dependent: :restrict_with_exception
  has_many :quote_items,
    -> { order(:sort_order, :id) },
    inverse_of: :quote,
    dependent: :destroy,
    autosave: true
  has_many :quote_change_requests,
    -> { order(requested_at: :desc, id: :desc) },
    inverse_of: :quote,
    dependent: :destroy

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validates :quote_number,
    numericality: {only_integer: true, greater_than: 0},
    uniqueness: {scope: :professional_id}
  validates :customer_name, length: {maximum: 80}
  validates :customer_phone_e164, length: {maximum: 20}, allow_nil: true
  validates :customer_email, length: {maximum: 254}, allow_nil: true
  validates :service_description, length: {maximum: 160}
  validates :service_address, length: {maximum: 240}, allow_nil: true
  validates :notes, length: {maximum: 700}, allow_nil: true
  validates :customer_decision_message, length: {in: 1..700}, allow_nil: true
  validates :status, inclusion: {in: STATUSES}
  validates :subtotal_amount, :discount_amount, :total_amount,
    numericality: {greater_than_or_equal_to: 0}
  validates :share_token_hash, format: {with: /\A[0-9a-f]{64}\z/}, uniqueness: true, allow_nil: true
  with_options unless: :draft? do
    validates :customer, presence: true
    validates :customer_name, presence: true
    validates :customer_phone_e164,
      presence: true,
      format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}
    validates :customer_email,
      format: {with: URI::MailTo::EMAIL_REGEXP},
      allow_nil: true
    validates :service_description, presence: true
    validates :valid_until, presence: true
  end
  validate :has_valid_item_count
  validate :discount_does_not_exceed_subtotal
  validate :share_state_matches_status
  validate :customer_belongs_to_professional
  validate :approved_content_is_immutable, on: :update

  before_validation :normalize_text
  before_validation :recalculate_totals

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  private

  def normalize_text
    self.customer_name = customer_name.to_s.squish
    self.customer_email = customer_email.to_s.strip.downcase.presence
    self.customer_phone_e164 = normalize_customer_phone
    self.service_description = service_description.to_s.squish
    self.service_address = service_address.to_s.squish.presence
    self.notes = notes.to_s.squish.presence
    self.customer_decision_message = customer_decision_message.to_s.squish.presence
  end

  def normalize_customer_phone
    return if customer_phone_e164.blank?

    BrazilianPhoneNumber.normalize(customer_phone_e164)
  rescue BrazilianPhoneNumber::Invalid
    errors.add(:customer_phone_e164, "não é um celular brasileiro válido") unless draft?
    customer_phone_e164.to_s.strip.presence
  end

  def recalculate_totals
    subtotal = quote_items.sum do |item|
      item.recalculate_line_total
      item.line_total || 0
    end
    self.subtotal_amount = BigDecimal(subtotal.to_s).round(MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
    self.discount_amount = BigDecimal(discount_amount.to_s.presence || "0").round(
      MONEY_SCALE,
      BigDecimal::ROUND_HALF_UP
    )
    self.total_amount = [subtotal_amount - discount_amount, BigDecimal(0)].max
  rescue ArgumentError
    # Numericality validations return the normalized field errors.
  end

  def has_valid_item_count
    minimum = draft? ? 0 : 1
    return if quote_items.length.between?(minimum, MAX_ITEMS)

    errors.add(:quote_items, "deve conter entre #{minimum} e #{MAX_ITEMS} itens")
  end

  def discount_does_not_exceed_subtotal
    return if draft?
    return unless discount_amount && subtotal_amount && discount_amount > subtotal_amount

    errors.add(:discount_amount, "não pode ultrapassar o subtotal")
  end

  def share_state_matches_status
    if draft? || saved?
      if share_token_hash.present? || share_token_ciphertext.present? || shared_at.present?
        errors.add(:status, :invalid)
      end
    elsif share_token_hash.blank? || share_token_ciphertext.blank? || shared_at.blank?
      errors.add(:status, :invalid)
    end
  end

  def customer_belongs_to_professional
    return unless customer && professional_id
    return if customer.professional_id == professional_id

    errors.add(:customer, :invalid)
  end

  def approved_content_is_immutable
    return unless status_in_database == "approved"
    return unless changes_to_save.except("updated_at", "lock_version").any?

    errors.add(:base, "um orçamento aprovado não pode ser alterado")
  end
end
