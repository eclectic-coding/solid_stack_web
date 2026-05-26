module SolidStackWeb
  class RecurringTasksController < ApplicationController
    def index
      @recurring_tasks = SolidQueue::RecurringTask.includes(:recurring_executions).order(:key)
    end
  end
end
