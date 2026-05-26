require "rails_helper"

RSpec.describe "RecurringTasks::Runs", type: :request do
  let(:engine_root) { "/solid_stack" }

  let!(:task) do
    SolidQueue::RecurringTask.create!(
      key: "nightly-cleanup",
      schedule: "0 2 * * *",
      command: "DailyCleanupJob.perform_later"
    )
  end

  before do
    allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue)
      .with(at: instance_of(ActiveSupport::TimeWithZone))
      .and_return(double("job", job_id: SecureRandom.uuid))
  end

  describe "POST /recurring_tasks/:key/run" do
    it "redirects to the recurring tasks page" do
      post "#{engine_root}/recurring_tasks/nightly-cleanup/run"
      expect(response).to redirect_to("#{engine_root}/recurring_tasks")
    end

    it "shows a success notice with the task key" do
      post "#{engine_root}/recurring_tasks/nightly-cleanup/run"
      follow_redirect!
      expect(response.body).to include("nightly-cleanup")
      expect(response.body).to include("queued for immediate execution")
    end

    it "redirects with alert for unknown task key" do
      post "#{engine_root}/recurring_tasks/nonexistent/run"
      expect(response).to redirect_to("#{engine_root}/recurring_tasks")
      follow_redirect!
      expect(response.body).to include("Recurring task not found")
    end

    it "shows an alert when enqueue returns false" do
      allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue).and_return(false)
      post "#{engine_root}/recurring_tasks/nightly-cleanup/run"
      follow_redirect!
      expect(response.body).to include("Could not enqueue")
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue).and_raise(RuntimeError, "boom")
      post "#{engine_root}/recurring_tasks/nightly-cleanup/run"
      expect(response).to redirect_to("#{engine_root}/recurring_tasks")
      follow_redirect!
      expect(response.body).to include("Could not run task")
    end
  end
end
