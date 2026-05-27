module SolidStackWeb
  class HistoryController < ApplicationController
    before_action :set_filters

    def index
      respond_to do |format|
        format.html { @pagy, @jobs = pagy(filtered_scope) }
        format.csv do
          send_data history_csv(filtered_scope),
                    filename: "job-history-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    private

    def set_filters
      @queue     = params[:queue].presence
      @search    = params[:q].presence
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @sort      = params[:sort].presence_in(sortable_columns) || "finished_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
    end

    def sortable_columns
      %w[class_name queue_name finished_at]
    end

    def sort_expression
      Arel.sql("#{@sort} #{@direction == 'asc' ? 'ASC' : 'DESC'}")
    end

    def filtered_scope
      scope = SolidQueue::Job.where.not(finished_at: nil).order(sort_expression)
      scope = scope.where(queue_name: @queue)                                 if @queue.present?
      scope = scope.where("class_name LIKE ?", "%#{@search}%")               if @search.present?
      scope = scope.where("finished_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope
    end

    def history_csv(scope)
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name duration_seconds finished_at]
        scope.each do |job|
          duration = job.finished_at && job.created_at ? (job.finished_at - job.created_at).round : nil
          csv << [job.id, job.class_name, job.queue_name, duration, job.finished_at.iso8601]
        end
      end
    end
  end
end
