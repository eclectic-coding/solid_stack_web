module SolidStackWeb
  class FailedJobsController < ApplicationController
    def index
      respond_to do |format|
        format.html do
          scope = ::SolidQueue::FailedExecution.includes(:job).order(created_at: :desc)
          @pagy, @executions = pagy(scope)
        end
        format.csv do
          send_data failed_jobs_csv,
                    filename: "failed-jobs-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
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

    private

    def failed_jobs_csv
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name error_class error_message failed_at]
        ::SolidQueue::FailedExecution.includes(:job).order(created_at: :desc).each do |execution|
          job   = execution.job
          error = execution.error || {}
          csv << [job.id, job.class_name, job.queue_name,
                  error["exception_class"], error["message"],
                  execution.created_at.iso8601]
        end
      end
    end
  end
end
