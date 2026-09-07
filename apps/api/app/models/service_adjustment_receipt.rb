# frozen_string_literal: true

class ServiceAdjustmentReceipt < ApplicationRecord
  belongs_to :service_adjustment_item
  belongs_to :media_upload

  validates :private_key, presence: true, uniqueness: true
  validates :content_type, inclusion: {in: MediaUpload::SUPPORTED_CONTENT_TYPES}
  validates :byte_size, :width, :height,
    numericality: {only_integer: true, greater_than: 0}
  validates :attached_at, presence: true
  validate :belongs_to_reimbursement_item

  delegate :service_adjustment, to: :service_adjustment_item

  private

  def belongs_to_reimbursement_item
    return if service_adjustment_item&.reimbursement?

    errors.add(:service_adjustment_item, "deve ser um reembolso de material")
  end
end
