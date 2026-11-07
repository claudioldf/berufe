# frozen_string_literal: true

# Validates a public support message and queues one e-mail per administrator
# address. Nothing is persisted: the message only travels in the job arguments.
class SupportMessageSubmitter
  TOPICS = %w[entrar criar-conta excluir-conta editar-perfil geral].freeze

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid support message")
    end
  end

  class Unavailable < StandardError; end

  def initialize(
    recipients: -> { Rails.application.config.x.berufe.environment.admin_notification_emails },
    delivery_job: SupportMessageDeliveryJob
  )
    @recipients = recipients
    @delivery_job = delivery_job
  end

  def call(attributes:)
    message = normalize(attributes)
    emails = @recipients.call
    raise Unavailable if emails.empty?

    emails.each { |email| @delivery_job.perform_later(email, message.stringify_keys) }
    message
  end

  private

  def normalize(attributes)
    name = attributes[:name].to_s.squish
    email = attributes[:email].to_s.strip.downcase
    text = attributes[:message].to_s.strip
    topic = attributes[:topic].to_s
    errors = {}

    errors[:name] = ["deve ter entre 2 e 120 caracteres"] unless (2..120).cover?(name.length)
    errors[:email] = ["informe um e-mail válido"] unless valid_email?(email)
    errors[:message] = ["deve ter entre 10 e 2000 caracteres"] unless (10..2000).cover?(text.length)
    errors[:topic] = ["assunto desconhecido"] unless TOPICS.include?(topic)
    phone = normalize_phone(attributes[:phone], errors)
    raise Invalid.new(errors) if errors.any?

    {name:, email:, phone:, message: text, topic:}
  end

  def valid_email?(email)
    email.length <= 254 && URI::MailTo::EMAIL_REGEXP.match?(email)
  end

  def normalize_phone(value, errors)
    return nil if value.to_s.strip.empty?

    BrazilianPhoneNumber.normalize(value)
  rescue BrazilianPhoneNumber::Invalid
    errors[:phone] = ["informe um celular brasileiro válido"]
    nil
  end
end
