module SolidStackWeb
  class ScheduledJobsController < ApplicationController
    def create
      @period  = params[:period].presence_in(PERIOD_DURATIONS.keys)
      job_ids  = scheduled_scope.pluck("solid_queue_jobs.id")
      SolidQueue::ScheduledExecution.where(job_id: job_ids).update_all(scheduled_at: 1.second.ago)
      SolidQueue::Job.where(id: job_ids).update_all(scheduled_at: 1.second.ago)
      redirect_to jobs_path(status: "scheduled", period: @period),
                  notice: "#{job_ids.size} #{"job".pluralize(job_ids.size)} scheduled to run immediately."
    rescue => e
      redirect_to jobs_path(status: "scheduled", period: @period),
                  alert: "Could not run jobs: #{e.message}"
    end

    def update
      @execution = SolidQueue::ScheduledExecution.find(params[:id])
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @run_now   = params[:offset] == "now"
      new_time   = resolve_new_time(@execution, params[:offset])

      @execution.update!(scheduled_at: new_time)
      @execution.job.update!(scheduled_at: new_time)

      respond_to do |format|
        format.turbo_stream
        format.html do
          notice = @run_now ? "Job scheduled to run immediately." : "Job rescheduled by +#{params[:offset]}."
          redirect_to jobs_path(status: "scheduled", period: @period), notice: notice
        end
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: "scheduled"), alert: e.message
    rescue => e
      redirect_to jobs_path(status: "scheduled"), alert: "Could not reschedule job: #{e.message}"
    end

    private

    def scheduled_scope
      scope = SolidQueue::ScheduledExecution.joins(:job)
      scope = scope.where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope
    end

    def resolve_new_time(execution, offset)
      return 1.second.ago if offset == "now"
      raise ArgumentError, "Invalid offset." unless PERIOD_DURATIONS.key?(offset)

      execution.scheduled_at + PERIOD_DURATIONS[offset]
    end
  end
end
