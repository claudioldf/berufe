# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "Berufe <nao-responda@berufe.com.br>") }
  layout "mailer"
end
