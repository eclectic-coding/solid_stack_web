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

    def pause
      ::SolidQueue::Pause.find_or_create_by!(queue_name: params[:id])
      redirect_to queues_path
    end

    def resume
      ::SolidQueue::Pause.find_by(queue_name: params[:id])&.destroy
      redirect_to queues_path
    end
  end
end
