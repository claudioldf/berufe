# frozen_string_literal: true

require_relative "../request_id_sanitizer"

module Berufe
  module BugsnagPrivacy
    REDACTED_KEYS = [
      /authorization/i,
      /body/i,
      /challenge/i,
      /cookie/i,
      /customer/i,
      /email/i,
      /file/i,
      /header/i,
      /otp/i,
      /param/i,
      /password/i,
      /phone/i,
      /secret/i,
      /session/i,
      /signed/i,
      /token/i,
      /url/i
    ].freeze
    CONTEXT_PATTERN = /\A(?:[a-z0-9_\/]+#[a-z0-9_!?]+|[A-Z]\w*(?:::[A-Z]\w*)*)\z/i
    JOB_CLASS_PATTERN = /\A[A-Z]\w*(?:::[A-Z]\w*)*\z/

    module_function

    def call(event)
      diagnostics = {
        request_id: valid_request_id(Current.request_id),
        context: valid_context(event.context),
        job_class: valid_job_class(metadata_value(event.metadata, :active_job, :job_name))
      }.compact

      event.metadata.keys.each { |section| event.clear_metadata(section) }
      event.set_user
      event.breadcrumbs = []
      event.session = nil
      event.add_metadata(:diagnostics, diagnostics) if diagnostics.any?
      true
    end

    def metadata_value(metadata, section, key)
      values = metadata[section] || metadata[section.to_s]
      return unless values.respond_to?(:[])

      values[key] || values[key.to_s]
    end
    private_class_method :metadata_value

    def valid_request_id(value)
      value if value.is_a?(String) && RequestIdSanitizer::VALID_REQUEST_ID.match?(value)
    end
    private_class_method :valid_request_id

    def valid_context(value)
      value if value.is_a?(String) && value.length <= 200 && CONTEXT_PATTERN.match?(value)
    end
    private_class_method :valid_context

    def valid_job_class(value)
      value if value.is_a?(String) && JOB_CLASS_PATTERN.match?(value)
    end
    private_class_method :valid_job_class
  end
end
