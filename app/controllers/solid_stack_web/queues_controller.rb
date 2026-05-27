module SolidStackWeb
  class QueuesController < ApplicationController
    def index
      counts = ::SolidQueue::ReadyExecution.group(:queue_name).count
      paused = ::SolidQueue::Pause.pluck(:queue_name).to_set

      @queues = counts.map { |name, size| { name:, size:, paused: paused.include?(name) } }
                      .sort_by { |q| q[:name] }

      @sparklines = @queues.each_with_object({}) do |queue, h|
        h[queue[:name]] = QueueDepthSparkline.new(queue[:name])
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
