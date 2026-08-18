# frozen_string_literal: true

class Quote < ApplicationRecord
  STATUSES = %w[draft shared].freeze
  MAX_ITEMS = 20
  MONEY_SCALE = 2

  belongs_to :professional, class_name: "ProfessionalProfile", inverse_of: :quotes
  has_many :quote_items,
    -> { order(:sort_order, :id) },
    inverse_of: :quote,
    dependent: :destroy,
    autosave: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validates :quote_number,
    numericality: {only_integer: true, greater_than: 0},
    uniqueness: {scope: :professional_id}
  validates :customer_name, length: {in: 1..80}
  validates :service_description, length: {in: 1..160}
  validates :notes, length: {maximum: 700}, allow_nil: true
  validates :status, inclusion: {in: STATUSES}
  validates :subtotal_amount, :discount_amount, :total_amount,
    numericality: {greater_than_or_equal_to: 0}
  validates :share_token_hash, format: {with: /\A[0-9a-f]{64}\z/}, uniqueness: true, allow_nil: true
  validate :has_valid_item_count
  validate :discount_does_not_exceed_subtotal
  validate :share_state_matches_status

  before_validation :normalize_text
  before_validation :recalculate_totals

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  private

  def normalize_text
    self.customer_name = customer_name.to_s.squish
    self.service_description = service_description.to_s.squish
    self.notes = notes.to_s.squish.presence
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
    return if quote_items.length.between?(1, MAX_ITEMS)

    errors.add(:quote_items, "deve conter entre 1 e #{MAX_ITEMS} itens")
  end

  def discount_does_not_exceed_subtotal
    return unless discount_amount && subtotal_amount && discount_amount > subtotal_amount

    errors.add(:discount_amount, "não pode ultrapassar o subtotal")
  end

  def share_state_matches_status
    if draft?
      errors.add(:status, :invalid) if share_token_hash.present? || shared_at.present?
    elsif share_token_hash.blank? || shared_at.blank?
      errors.add(:status, :invalid)
    end
  end
end
