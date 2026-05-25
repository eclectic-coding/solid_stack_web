module SolidStackWeb
  class FailedJobsController < ApplicationController
    def index
      scope = ::SolidQueue::FailedExecution.includes(:job).order(created_at: :desc)
      @pagy, @executions = pagy(scope)
    end

    def destroy
      @execution = ::SolidQueue::FailedExecution.find(params[:id])
      @execution.job.destroy!
      @executions_remain = ::SolidQueue::FailedExecution.exists?

      respond_to do |format|
        format.html { redirect_to failed_jobs_path }
        format.turbo_stream
      end
    end

    def retry
      execution = ::SolidQueue::FailedExecution.find(params[:id])
      execution.retry
      redirect_to failed_jobs_path
    end
  end
end
