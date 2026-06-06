module SolidStackWeb
  class RecurringTasks::RunsController < ApplicationController
    def create
      task = SolidQueue::RecurringTask.find_by!(key: params[:recurring_task_key])
      result = task.enqueue(at: Time.current)

      if result
        redirect_to recurring_tasks_path, notice: t("solid_stack_web.flash.task_queued", key: task.key)
      else
        redirect_to recurring_tasks_path, alert: t("solid_stack_web.flash.cannot_enqueue_task", key: task.key)
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to recurring_tasks_path, alert: t("solid_stack_web.flash.task_not_found")
    rescue => e
      redirect_to recurring_tasks_path, alert: t("solid_stack_web.flash.cannot_run_task", error: e.message)
    end
  end
end
