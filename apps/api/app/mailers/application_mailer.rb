# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "Berufe <nao-responda@berufe.com.br>") }
  before_action :set_layout_context
  layout "mailer"

  private

  def set_layout_context
    @web_origin = ENV.fetch("WEB_ORIGIN").delete_suffix("/")
  end
end
