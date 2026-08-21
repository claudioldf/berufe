# frozen_string_literal: true

class Customer < ApplicationRecord
  belongs_to :professional, class_name: "ProfessionalProfile", inverse_of: :customers
  has_many :quotes, dependent: :restrict_with_exception
  has_many :customer_recommendations, dependent: :restrict_with_exception

  validates :name, length: {in: 1..80}
  validates :whatsapp_e164, presence: true, format: {with: UserAccount::BRAZILIAN_MOBILE_PATTERN}
  validates :email, length: {maximum: 254}, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_nil: true

  before_validation :normalize_fields

  private

  def normalize_fields
    self.name = name.to_s.squish
    self.email = email.to_s.strip.downcase.presence
    self.whatsapp_e164 = BrazilianPhoneNumber.normalize(whatsapp_e164)
  rescue BrazilianPhoneNumber::Invalid
    errors.add(:whatsapp_e164, "não é um celular brasileiro válido")
  end
end
