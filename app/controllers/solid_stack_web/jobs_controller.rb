module SolidStackWeb
  class JobsController < ApplicationController
    before_action :set_status
    before_action :set_filters, only: :index
    before_action :require_discardable, only: :destroy

    def index
      @queue_options    = Job::EXECUTION_MODELS[@status].joins(:job).distinct.pluck("solid_queue_jobs.queue_name").sort
      @priority_options = Job::EXECUTION_MODELS[@status].joins(:job).distinct.pluck("solid_queue_jobs.priority").sort

      @pagy, @executions = pagy(filtered_scope)
    end

    def show
      @execution = Job::EXECUTION_MODELS[@status].includes(:job).find(params[:id])
      @job = @execution.job
      @arguments = JSON.parse(@job.arguments) if @job.arguments.present?
    rescue JSON::ParserError
      @arguments = nil
    end

    def destroy
      @execution = Job::EXECUTION_MODELS[@status].find(params[:id])
      @execution.job.destroy!
      @executions_remain = Job::EXECUTION_MODELS[@status].exists?

      respond_to do |format|
        format.html { redirect_to jobs_path(status: @status, q: params[:q], queue: params[:queue], period: params[:period], priority: params[:priority]) }
        format.turbo_stream
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
