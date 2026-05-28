module SolidStackWeb
  class FailedJobsController < ApplicationController
    def index
      @sort      = params[:sort].presence_in(sortable_columns) || "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"

      respond_to do |format|
        format.html do
          scope = ::SolidQueue::FailedExecution.includes(:job).references(:job).order(sort_expression)
          @error_class = params[:error_class].presence
          scope = scope.where(id: ids_for_error_class(@error_class)) if @error_class
          @pagy, @executions = pagy(scope)
        end
        format.csv do
          send_data failed_jobs_csv,
                    filename: "failed-jobs-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    def show
      @execution = ::SolidQueue::FailedExecution.includes(:job).find(params[:id])
      @arguments = JSON.pretty_generate(@execution.job.arguments) if @execution.job.arguments.present?
    rescue JSON::GeneratorError
      @arguments = @execution.job.arguments.to_s
    end

    def destroy
      @execution = ::SolidQueue::FailedExecution.find(params[:id])
      job_class  = @execution.job.class_name
      queue_name = @execution.job.queue_name
      @execution.job.destroy!
      record_audit("failed_job_discarded", job_class: job_class, queue_name: queue_name)
      @executions_remain = ::SolidQueue::FailedExecution.exists?
      @notice = "Job discarded."

      respond_to do |format|
        format.html { redirect_to failed_jobs_path }
        format.turbo_stream
      end
    end

    def retry
      execution = ::SolidQueue::FailedExecution.find(params[:id])
      record_audit("failed_job_retried", job_class: execution.job.class_name, queue_name: execution.job.queue_name)
      execution.retry
      redirect_to failed_jobs_path, notice: "Job retried."
    end

    private

    def sortable_columns
      %w[class_name queue_name created_at]
    end

    def sort_expression
      sql_col = case @sort
      when "class_name" then "solid_queue_jobs.class_name"
      when "queue_name" then "solid_queue_jobs.queue_name"
      else "solid_queue_failed_executions.created_at"
      end
      Arel.sql("#{sql_col} #{@direction == 'asc' ? 'ASC' : 'DESC'}")
    end

    def ids_for_error_class(ec)
      ::SolidQueue::FailedExecution.pluck(:id, :error).filter_map do |id, raw|
        error = raw.is_a?(Hash) ? raw : JSON.parse(raw)
        id if error["exception_class"] == ec
      rescue StandardError
        nil
      end
    end

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
