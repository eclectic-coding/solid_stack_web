module SolidStackWeb
  class Queues::PausesController < ApplicationController
    def create
      ::SolidQueue::Pause.find_or_create_by!(queue_name: params[:queue_id])
      record_audit("queue_paused", queue_name: params[:queue_id])
      redirect_back_or_to queues_path
    end

    def destroy
      ::SolidQueue::Pause.find_by(queue_name: params[:queue_id])&.destroy
      record_audit("queue_resumed", queue_name: params[:queue_id])
      redirect_back_or_to queues_path
    end
  end
end
