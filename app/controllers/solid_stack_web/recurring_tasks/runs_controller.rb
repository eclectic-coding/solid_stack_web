module SolidStackWeb
  class RecurringTasks::RunsController < ApplicationController
    def create
      task = SolidQueue::RecurringTask.find_by!(key: params[:recurring_task_key])
      result = task.enqueue(at: Time.current)

      if result
        redirect_to recurring_tasks_path, notice: "\"#{task.key}\" queued for immediate execution."
      else
        redirect_to recurring_tasks_path, alert: "Could not enqueue \"#{task.key}\" — it may have just run."
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to recurring_tasks_path, alert: "Recurring task not found."
    rescue => e
      redirect_to recurring_tasks_path, alert: "Could not run task: #{e.message}"
    end
  end
end
