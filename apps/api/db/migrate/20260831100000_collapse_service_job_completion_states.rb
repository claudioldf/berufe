# frozen_string_literal: true

class CollapseServiceJobCompletionStates < ActiveRecord::Migration[8.1]
  def up
    # Pre-launch reset: no in-flight completion_requested/completion_issue job
    # carries a real customer commitment worth preserving through the shape
    # change. See RestrictModerationToIdentityVerification for the same
    # precedent.
    execute "UPDATE service_jobs SET status = 'approved' WHERE status IN ('completion_requested', 'completion_issue')"

    remove_check_constraint :service_jobs, name: "service_jobs_known_status"
    add_check_constraint :service_jobs,
      "status IN ('approved', 'completed', 'cancelled')",
      name: "service_jobs_known_status"

    remove_check_constraint :service_jobs, name: "service_jobs_consistent_completion_confirmer"
    remove_column :service_jobs, :completion_confirmed_by, :string, limit: 20

    remove_column :service_jobs, :completion_requested_at, :datetime
    remove_column :service_jobs, :completion_issue_at, :datetime

    remove_check_constraint :service_jobs, name: "service_jobs_completion_issue_message_length"
    rename_column :service_jobs, :completion_issue_message, :customer_feedback_message
    add_check_constraint :service_jobs,
      "customer_feedback_message IS NULL OR " \
        "char_length(btrim(customer_feedback_message)) BETWEEN 1 AND 700",
      name: "service_jobs_customer_feedback_message_length"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the completion-lifecycle simplification requires a database reset"
  end
end
