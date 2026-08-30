# frozen_string_literal: true

class TrackServiceCompletionConfirmer < ActiveRecord::Migration[8.1]
  def up
    add_column :service_jobs, :completion_confirmed_by, :string, limit: 20
    execute <<~SQL.squish
      UPDATE service_jobs
      SET completion_confirmed_by = 'customer'
      WHERE status = 'completed'
    SQL
    add_check_constraint :service_jobs,
      "(status = 'completed' AND completion_confirmed_by IN ('customer', 'professional')) OR " \
        "(status <> 'completed' AND completion_confirmed_by IS NULL)",
      name: "service_jobs_consistent_completion_confirmer"
  end

  def down
    remove_check_constraint :service_jobs,
      name: "service_jobs_consistent_completion_confirmer"
    remove_column :service_jobs, :completion_confirmed_by
  end
end
