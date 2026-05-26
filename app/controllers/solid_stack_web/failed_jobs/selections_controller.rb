module SolidStackWeb
  module FailedJobs
    class SelectionsController < ApplicationController
      before_action :set_ids

      def create
        SolidQueue::FailedExecution.where(id: @ids).each(&:retry)
        redirect_to failed_jobs_path
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not retry jobs: #{e.message}"
      end

      def destroy
        job_ids = SolidQueue::FailedExecution.where(id: @ids).pluck(:job_id)
        SolidQueue::Job.where(id: job_ids).destroy_all
        redirect_to failed_jobs_path
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
