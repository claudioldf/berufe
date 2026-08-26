# frozen_string_literal: true

module Berufe
  module Reporting
    LLM_SEARCH_AUDIT_RETENTION_MONTHS = 6

    module_function

    def llm_search_audit_retention_months(settings: Rails.configuration.x.berufe.reporting)
      settings.llm_search_audit_retention_months || LLM_SEARCH_AUDIT_RETENTION_MONTHS
    end

    def llm_search_audit_window_start(time, settings: Rails.configuration.x.berufe.reporting)
      time - llm_search_audit_retention_months(settings:).months
    end
  end
end
