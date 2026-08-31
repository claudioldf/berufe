# frozen_string_literal: true

class CustomerRecommendationMailerPreview < ActionMailer::Preview
  def invitation
    CustomerRecommendationMailer.with(
      request_record: preview_request,
      token: "preview-recommendation-token"
    ).invitation
  end

  private

  def preview_request
    revision = Data.define(:display_name).new("Claudio Dias")
    professional = Data.define(:published_revision, :working_revision).new(revision, nil)
    quote = Data.define(
      :customer_name,
      :customer_email,
      :service_description,
      :professional
    ).new(
      "Marina Oliveira",
      "marina@example.com",
      "Instalação e revisão de luminárias",
      professional
    )
    service_job = Data.define(:quote).new(quote)

    Data.define(:service_job).new(service_job)
  end
end
