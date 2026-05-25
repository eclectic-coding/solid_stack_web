module SolidStackWeb
  module FailedJobs
    class ArgumentsController < ApplicationController
      def update
        @execution = SolidQueue::FailedExecution.includes(:job).find(params[:failed_job_id])
        new_arguments = JSON.parse(params[:arguments])
        @execution.job.update!(arguments: new_arguments)
        @execution.retry
        redirect_to failed_jobs_path, notice: "Arguments updated and job queued for retry."
      rescue JSON::ParserError
        redirect_to failed_job_path(@execution), alert: "Invalid JSON — arguments were not saved."
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not update job: #{e.message}"
      end
    end
  end
end
