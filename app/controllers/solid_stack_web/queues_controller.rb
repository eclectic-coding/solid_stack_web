module SolidStackWeb
  class QueuesController < ApplicationController
    def index
      queue_names = ::SolidQueue::ReadyExecution.distinct.pluck(:queue_name)
      paused      = ::SolidQueue::Pause.pluck(:queue_name).to_set

      @queues = queue_names.sort.map do |name|
        {
          name:   name,
          size:   ::SolidQueue::ReadyExecution.where(queue_name: name).count,
          paused: paused.include?(name)
        }
      end
    end

    def show
      @queue_name = params[:id]
      @paused     = ::SolidQueue::Pause.exists?(queue_name: @queue_name)
      @pagy, @executions = pagy(
        ::SolidQueue::ReadyExecution
          .where(queue_name: @queue_name)
          .includes(:job)
          .order(created_at: :desc)
      )
    end
  end
end
