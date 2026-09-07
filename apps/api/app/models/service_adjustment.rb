# frozen_string_literal: true

class ServiceAdjustment < ApplicationRecord
  STATUSES = %w[draft awaiting_response change_requested approved declined cancelled].freeze
  EDITABLE_STATUSES = %w[draft awaiting_response change_requested].freeze
  TERMINAL_STATUSES = %w[approved declined cancelled].freeze
  MAX_ITEMS = 20
  MONEY_SCALE = 2

  belongs_to :service_job
  has_many :service_adjustment_items,
    -> { order(:sort_order, :id) },
    inverse_of: :service_adjustment,
    dependent: :destroy,
    autosave: true
  has_many :service_adjustment_change_requests,
    -> { order(requested_at: :desc, id: :desc) },
    inverse_of: :service_adjustment,
    dependent: :destroy

  validates :adjustment_number,
    numericality: {only_integer: true, greater_than: 0},
    uniqueness: {scope: :service_job_id}
  validates :status, inclusion: {in: STATUSES}
  validates :title, length: {in: 1..120}
  validates :description, length: {in: 1..700}, allow_nil: true
  validates :schedule_impact, length: {in: 1..300}, allow_nil: true
  validates :customer_decision_message, length: {in: 1..700}, allow_nil: true
  validates :total_amount, numericality: true
  validate :has_valid_item_count
  validate :terminal_content_is_immutable, on: :update

  before_validation :normalize_text
  before_validation :recalculate_total

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  def editable?
    status.in?(EDITABLE_STATUSES)
  end

  def unresolved?
    !status.in?(TERMINAL_STATUSES)
  end

  def recalculate_total
    self.total_amount = service_adjustment_items.sum do |item|
      item.recalculate_line_total
      item.line_total || 0
    end.to_d.round(MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
  rescue ArgumentError
    # Numericality validations expose malformed values.
  end

  private

  def normalize_text
    self.title = title.to_s.squish
    self.description = description.to_s.squish.presence
    self.schedule_impact = schedule_impact.to_s.squish.presence
    self.customer_decision_message = customer_decision_message.to_s.squish.presence
    self.accepted_customer_name = accepted_customer_name.to_s.squish.presence
    self.accepted_customer_phone_e164 = accepted_customer_phone_e164.to_s.strip.presence
    self.accepted_customer_email = accepted_customer_email.to_s.strip.downcase.presence
  end

  def has_valid_item_count
    return if service_adjustment_items.length.between?(0, MAX_ITEMS)

    errors.add(:service_adjustment_items, "deve conter no máximo #{MAX_ITEMS} itens")
  end

  def terminal_content_is_immutable
    return unless status_in_database.in?(TERMINAL_STATUSES)
    return if changes_to_save.except("updated_at", "lock_version").empty?

    errors.add(:base, "um ajuste aprovado, recusado ou cancelado não pode ser alterado")
  end
end
