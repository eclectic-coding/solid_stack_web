module SolidStackWeb
  class AuditEvent < ActiveRecord::Base
    self.table_name = "solid_stack_web_audit_events"

    ACTIONS = %w[
      job_discarded jobs_discarded
      failed_job_retried failed_jobs_retried
      failed_job_discarded failed_jobs_discarded
      queue_paused queue_resumed
    ].freeze

    validates :action,     presence: true, inclusion: { in: ACTIONS }
    validates :item_count, numericality: { greater_than: 0 }

    scope :recent, -> { order(created_at: :desc) }
  end
end
