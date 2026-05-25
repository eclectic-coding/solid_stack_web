module SolidStackWeb
  class JobsController < ApplicationController
    before_action :set_status
    before_action :set_filters, only: [:index, :destroy]
    before_action :require_discardable, only: :destroy

    def index
      @queue_options    = Job::EXECUTION_MODELS[@status].joins(:job).distinct.pluck("solid_queue_jobs.queue_name").sort
      @priority_options = Job::EXECUTION_MODELS[@status].joins(:job).distinct.pluck("solid_queue_jobs.priority").sort

      respond_to do |format|
        format.html { @pagy, @executions = pagy(filtered_scope) }
        format.csv do
          send_data jobs_csv,
                    filename: "jobs-#{@status}-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    def show
      @execution = Job::EXECUTION_MODELS[@status].includes(:job).find(params[:id])
      @arguments = JSON.parse(@execution.job.arguments) if @execution.job.arguments.present?
    rescue JSON::ParserError
      @arguments = nil
    end

    def destroy
      if params[:id]
        @execution = Job::EXECUTION_MODELS[@status].find(params[:id])
        @execution.job.destroy!
        @executions_remain = Job::EXECUTION_MODELS[@status].exists?

        respond_to do |format|
          format.html { redirect_to jobs_path(status: @status, q: @search, queue: @queue, period: @period, priority: @priority) }
          format.turbo_stream
        end
      else
        job_ids = filtered_scope.pluck(:job_id)
        SolidQueue::Job.where(id: job_ids).destroy_all
        redirect_to jobs_path(status: @status, q: @search, queue: @queue, period: @period, priority: @priority)
      end
    end

    private

    def set_status
      @status = params[:status].presence_in(Job::STATUSES) || "ready"
    end

    def set_filters
      @search   = params[:q].presence
      @queue    = params[:queue].presence
      @period   = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @priority = params[:priority].presence
    end

    def require_discardable
      head :unprocessable_content unless Job::DISCARDABLE.include?(@status)
    end

    def jobs_csv
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name status priority enqueued_at]
        filtered_scope.each do |execution|
          job = execution.job
          csv << [job.id, job.class_name, job.queue_name, @status, job.priority, job.created_at.iso8601]
        end
      end
    end

    def filtered_scope
      scope = Job::EXECUTION_MODELS[@status].includes(:job).order(created_at: :desc)
      scope = scope.references(:job).where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
      scope = scope.references(:job).where("solid_queue_jobs.queue_name = ?", @queue)             if @queue.present?
      scope = scope.references(:job).where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope = scope.references(:job).where("solid_queue_jobs.priority = ?", @priority.to_i)       if @priority.present?
      scope
    end
  end
end
