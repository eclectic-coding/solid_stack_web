module SolidStackWeb
  module FailedJobs
    class SelectionsController < ApplicationController
      def create
        ids = Array(params[:job_ids]).map(&:to_i).reject(&:zero?)
        SolidQueue::FailedExecution.where(id: ids).each(&:retry)
        redirect_to failed_jobs_path
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not retry jobs: #{e.message}"
      end

      def destroy
        ids     = Array(params[:job_ids]).map(&:to_i).reject(&:zero?)
        job_ids = SolidQueue::FailedExecution.where(id: ids).pluck(:job_id)
        SolidQueue::Job.where(id: job_ids).destroy_all
        redirect_to failed_jobs_path
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not discard jobs: #{e.message}"
      end
    end
  end
end
