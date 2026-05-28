module SolidStackWeb
  module FailedJobs
    class SelectionsController < ApplicationController
      before_action :set_ids

      def create
        count = @ids.size
        SolidQueue::FailedExecution.where(id: @ids).each(&:retry)
        record_audit("failed_jobs_retried", item_count: count)
        redirect_to failed_jobs_path, notice: "#{count} #{count == 1 ? "job" : "jobs"} retried."
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not retry jobs: #{e.message}"
      end

      def destroy
        job_ids = SolidQueue::FailedExecution.where(id: @ids).pluck(:job_id)
        count = SolidQueue::Job.where(id: job_ids).destroy_all.size
        record_audit("failed_jobs_discarded", item_count: count)
        redirect_to failed_jobs_path, notice: "#{count} #{count == 1 ? "job" : "jobs"} discarded."
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not discard jobs: #{e.message}"
      end

      private

      def set_ids
        @ids = Array(params[:job_ids]).map(&:to_i).reject(&:zero?)
      end
    end
  end
end
