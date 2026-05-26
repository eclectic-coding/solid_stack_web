module SolidStackWeb
  module Jobs
    class SelectionsController < ApplicationController
      def destroy
        status = params[:status].presence_in(Job::STATUSES) || "ready"
        raise ArgumentError, "Cannot discard #{status} jobs." unless Job::DISCARDABLE.include?(status)

        ids     = Array(params[:job_ids]).map(&:to_i).reject(&:zero?)
        job_ids = Job::EXECUTION_MODELS[status].where(id: ids).pluck(:job_id)
        count   = SolidQueue::Job.where(id: job_ids).destroy_all.size

        redirect_to jobs_path(
          status: status,
          q:        params[:q].presence,
          queue:    params[:queue].presence,
          period:   params[:period].presence_in(PERIOD_DURATIONS.keys),
          priority: params[:priority].presence
        ), notice: "#{count} #{count == 1 ? "job" : "jobs"} discarded."
      rescue ArgumentError => e
        redirect_to jobs_path(status: params[:status]), alert: e.message
      end
    end
  end
end
