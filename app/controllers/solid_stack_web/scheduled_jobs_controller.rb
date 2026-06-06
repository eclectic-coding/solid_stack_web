module SolidStackWeb
  class ScheduledJobsController < ApplicationController
    def create
      @period  = params[:period].presence_in(PERIOD_DURATIONS.keys)
      job_ids  = scheduled_scope.pluck("solid_queue_jobs.id")
      SolidQueue::ScheduledExecution.where(job_id: job_ids).update_all(scheduled_at: 1.second.ago)
      SolidQueue::Job.where(id: job_ids).update_all(scheduled_at: 1.second.ago)
      redirect_to jobs_path(status: "scheduled", period: @period),
                  notice: t("solid_stack_web.flash.jobs_run_immediately", count: job_ids.size)
    rescue => e
      redirect_to jobs_path(status: "scheduled", period: @period),
                  alert: t("solid_stack_web.flash.cannot_run_jobs", error: e.message)
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
          notice = @run_now ? t("solid_stack_web.flash.job_run_immediately") : t("solid_stack_web.flash.job_rescheduled", offset: params[:offset])
          redirect_to jobs_path(status: "scheduled", period: @period), notice: notice
        end
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: "scheduled"), alert: e.message
    rescue => e
      redirect_to jobs_path(status: "scheduled"), alert: t("solid_stack_web.flash.cannot_reschedule_job", error: e.message)
    end

    private

    def scheduled_scope
      scope = SolidQueue::ScheduledExecution.joins(:job)
      scope = scope.where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope
    end

    def resolve_new_time(execution, offset)
      return 1.second.ago if offset == "now"
      raise ArgumentError, t("solid_stack_web.flash.invalid_offset") unless PERIOD_DURATIONS.key?(offset)

      execution.scheduled_at + PERIOD_DURATIONS[offset]
    end
  end
end
