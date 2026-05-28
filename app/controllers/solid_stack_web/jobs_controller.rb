module SolidStackWeb
  class JobsController < ApplicationController
    before_action :set_status
    before_action :set_filters, only: [:index, :destroy]
    before_action :require_discardable, only: [:destroy]

    def index
      pairs = Job::EXECUTION_MODELS[@status].joins(:job)
                .distinct
                .pluck("solid_queue_jobs.queue_name", "solid_queue_jobs.priority")
      @queue_options    = pairs.map(&:first).uniq.sort
      @priority_options = pairs.map(&:last).uniq.sort

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
        job_class  = @execution.job.class_name
        queue_name = @execution.job.queue_name
        @execution.job.destroy!
        record_audit("job_discarded", job_class: job_class, queue_name: queue_name)
        @executions_remain = Job::EXECUTION_MODELS[@status].exists?
        @notice = "Job discarded."

        respond_to do |format|
          format.html { redirect_to jobs_path(status: @status, q: @search, queue: @queue, period: @period, priority: @priority, sort: @sort, direction: @direction) }
          format.turbo_stream
        end
      else
        job_ids = filtered_scope.pluck(:job_id)
        count = SolidQueue::Job.where(id: job_ids).destroy_all.size
        record_audit("jobs_discarded", item_count: count)
        redirect_to jobs_path(status: @status, q: @search, queue: @queue, period: @period, priority: @priority, sort: @sort, direction: @direction),
                    notice: "#{count} #{count == 1 ? "job" : "jobs"} discarded."
      end
    end

    private

    def set_status
      @status = params[:status].presence_in(Job::STATUSES) || "ready"
    end

    def set_filters
      @search    = params[:q].presence
      @queue     = params[:queue].presence
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @priority  = params[:priority].presence
      @sort      = params[:sort].presence_in(sortable_columns) || "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
    end

    def sortable_columns
      %w[class_name queue_name priority created_at]
    end

    def sort_expression
      sql_col = case @sort
      when "class_name" then "solid_queue_jobs.class_name"
      when "queue_name" then "solid_queue_jobs.queue_name"
      when "priority"   then "solid_queue_jobs.priority"
      else "#{Job::EXECUTION_MODELS[@status].quoted_table_name}.created_at"
      end
      Arel.sql("#{sql_col} #{@direction == 'asc' ? 'ASC' : 'DESC'}")
    end

    def require_discardable
      head :unprocessable_content unless Job::DISCARDABLE.include?(@status)
    end

    def jobs_csv
      CSV.generate(headers: true) do |csv|
        headers = %w[id class_name queue_name status priority enqueued_at]
        headers << "wait_time_seconds" if @status == "claimed"
        csv << headers
        filtered_scope.each do |execution|
          job = execution.job
          row = [job.id, job.class_name, job.queue_name, @status, job.priority, job.created_at.iso8601]
          row << (execution.created_at - job.created_at).to_i if @status == "claimed"
          csv << row
        end
      end
    end

    def filtered_scope
      scope = Job::EXECUTION_MODELS[@status].includes(:job).references(:job).order(sort_expression)
      scope = scope.where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
      scope = scope.where("solid_queue_jobs.queue_name = ?", @queue)             if @queue.present?
      scope = scope.where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope = scope.where("solid_queue_jobs.priority = ?", @priority.to_i)       if @priority.present?
      scope
    end
  end
end
