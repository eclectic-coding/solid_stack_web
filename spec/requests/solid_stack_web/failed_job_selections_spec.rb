require "rails_helper"

RSpec.describe "Failed Job Selections", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_failed(class_name: "FailingJob", queue_name: "default")
    SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
    job = SolidQueue::Job.create!(
      class_name:, queue_name:, priority: 0,
      arguments: { "executions" => 0, "exception_executions" => {} }
    )
    execution = SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class: "RuntimeError", message: "something went wrong",
               backtrace: ["app/jobs/failing_job.rb:5"] }
    )
    SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
    execution
  end

  describe "POST /failed_jobs/selection (bulk retry)" do
    it "redirects with alert when retry raises" do
      execution = create_failed
      allow_any_instance_of(SolidQueue::FailedExecution).to receive(:retry).and_raise(RuntimeError, "db error")

      post "#{engine_root}/failed_jobs/selection",
           params: { job_ids: [execution.id] }

      expect(response).to redirect_to("#{engine_root}/failed_jobs")
      expect(flash[:alert]).to eq("Could not retry jobs: db error")
    end

    it "retries only the selected jobs" do
      exec_a = create_failed(class_name: "JobA")
      exec_b = create_failed(class_name: "JobB")

      post "#{engine_root}/failed_jobs/selection",
           params: { job_ids: [exec_a.id] }

      expect(SolidQueue::FailedExecution.exists?(exec_a.id)).to be false
      expect(SolidQueue::FailedExecution.exists?(exec_b.id)).to be true
    end

    it "redirects to the failed jobs list" do
      exec_a = create_failed

      post "#{engine_root}/failed_jobs/selection",
           params: { job_ids: [exec_a.id] }

      expect(response).to redirect_to("#{engine_root}/failed_jobs")
    end

    it "retries multiple selected jobs" do
      exec_a = create_failed(class_name: "JobA")
      exec_b = create_failed(class_name: "JobB")

      post "#{engine_root}/failed_jobs/selection",
           params: { job_ids: [exec_a.id, exec_b.id] }

      expect(SolidQueue::FailedExecution.count).to eq(0)
    end

    it "is a no-op when no job_ids are submitted" do
      create_failed

      post "#{engine_root}/failed_jobs/selection", params: { job_ids: [] }

      expect(SolidQueue::FailedExecution.count).to eq(1)
    end
  end

  describe "DELETE /failed_jobs/selection (bulk discard)" do
    it "redirects with alert when discard raises" do
      execution = create_failed
      allow(SolidQueue::Job).to receive(:where).and_raise(RuntimeError, "db error")

      delete "#{engine_root}/failed_jobs/selection",
             params: { job_ids: [execution.id] }

      expect(response).to redirect_to("#{engine_root}/failed_jobs")
      expect(flash[:alert]).to eq("Could not discard jobs: db error")
    end

    it "discards only the selected jobs" do
      exec_a = create_failed(class_name: "JobA")
      exec_b = create_failed(class_name: "JobB")

      delete "#{engine_root}/failed_jobs/selection",
             params: { job_ids: [exec_a.id] }

      expect(SolidQueue::FailedExecution.exists?(exec_a.id)).to be false
      expect(SolidQueue::FailedExecution.exists?(exec_b.id)).to be true
    end

    it "redirects to the failed jobs list" do
      exec_a = create_failed

      delete "#{engine_root}/failed_jobs/selection",
             params: { job_ids: [exec_a.id] }

      expect(response).to redirect_to("#{engine_root}/failed_jobs")
    end

    it "discards multiple selected jobs" do
      exec_a = create_failed(class_name: "JobA")
      exec_b = create_failed(class_name: "JobB")

      delete "#{engine_root}/failed_jobs/selection",
             params: { job_ids: [exec_a.id, exec_b.id] }

      expect(SolidQueue::FailedExecution.count).to eq(0)
    end

    it "is a no-op when no job_ids are submitted" do
      create_failed

      delete "#{engine_root}/failed_jobs/selection", params: { job_ids: [] }

      expect(SolidQueue::FailedExecution.count).to eq(1)
    end
  end

  describe "GET /failed_jobs with selection UI" do
    it "renders checkboxes and both selection forms when failed jobs exist" do
      create_failed

      get "#{engine_root}/failed_jobs"

      expect(response.body).to include('type="checkbox"')
      expect(response.body).to include('id="retry-selection-form"')
      expect(response.body).to include('id="discard-selection-form"')
    end

    it "does not render the selection UI when there are no failed jobs" do
      get "#{engine_root}/failed_jobs"

      expect(response.body).not_to include('retry-selection-form')
    end
  end
end
