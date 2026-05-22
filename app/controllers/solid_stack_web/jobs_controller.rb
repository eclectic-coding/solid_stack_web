module SolidStackWeb
  class JobsController < ApplicationController
    EXECUTION_MODELS = {
      "ready"     => ::SolidQueue::ReadyExecution,
      "scheduled" => ::SolidQueue::ScheduledExecution,
      "claimed"   => ::SolidQueue::ClaimedExecution,
      "blocked"   => ::SolidQueue::BlockedExecution,
    }.freeze

    DISCARDABLE = %w[ready scheduled blocked].freeze

    before_action :set_status
    before_action :require_discardable, only: :destroy

    def index
      scope = EXECUTION_MODELS[@status].includes(:job).order(created_at: :desc)
      @pagy, @executions = pagy(scope)
    end

    def destroy
      model     = EXECUTION_MODELS[@status]
      execution = model.find(params[:id])
      execution.job.destroy!
      @executions_remain = model.exists?

      respond_to do |format|
        format.html { redirect_to jobs_path(status: @status) }
        format.turbo_stream
      end
    end

    private

    def set_status
      @status = params[:status].presence_in(EXECUTION_MODELS.keys) || "ready"
    end

    def require_discardable
      head :unprocessable_entity unless DISCARDABLE.include?(@status)
    end
  end
end
