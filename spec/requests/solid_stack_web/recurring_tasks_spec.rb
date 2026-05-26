require "rails_helper"

RSpec.describe "RecurringTasks", type: :request do
  let(:engine_root) { "/solid_stack" }

  let!(:static_task) do
    SolidQueue::RecurringTask.create!(
      key: "nightly-cleanup",
      schedule: "0 2 * * *",
      command: "DailyCleanupJob.perform_later",
      queue_name: "default",
      description: "Nightly database cleanup",
      static: true
    )
  end

  let!(:dynamic_task) do
    SolidQueue::RecurringTask.create!(
      key: "weekly-report",
      schedule: "0 8 * * 1",
      command: "ReportJob.perform_later",
      static: false
    )
  end

  describe "GET /recurring_tasks" do
    it "returns HTTP success" do
      get "#{engine_root}/recurring_tasks"
      expect(response).to have_http_status(:ok)
    end

    it "displays task keys" do
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("nightly-cleanup")
      expect(response.body).to include("weekly-report")
    end

    it "displays the schedule" do
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("0 2 * * *")
    end

    it "displays the description" do
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("Nightly database cleanup")
    end

    it "distinguishes static and dynamic tasks" do
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("Static")
      expect(response.body).to include("Dynamic")
    end

    it "shows a Run Now button for each task" do
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("Run Now")
    end

    it "shows empty state when no tasks exist" do
      SolidQueue::RecurringTask.delete_all
      get "#{engine_root}/recurring_tasks"
      expect(response.body).to include("No recurring tasks")
    end
  end
end
