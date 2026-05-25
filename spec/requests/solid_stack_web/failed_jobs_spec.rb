require "rails_helper"

RSpec.describe "FailedJobs", type: :request do
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

  describe "GET /failed_jobs" do
    it "returns 200" do
      get "#{engine_root}/failed_jobs"
      expect(response).to have_http_status(:ok)
    end

    it "shows an empty state when there are no failed jobs" do
      get "#{engine_root}/failed_jobs"
      expect(response.body).to include("No failed jobs")
    end

    it "lists failed job class names" do
      create_failed(class_name: "FailingJob")
      get "#{engine_root}/failed_jobs"
      expect(response.body).to include("FailingJob")
    end

    it "shows the queue name" do
      create_failed(queue_name: "critical")
      get "#{engine_root}/failed_jobs"
      expect(response.body).to include("critical")
    end

    it "shows the exception class" do
      create_failed
      get "#{engine_root}/failed_jobs"
      expect(response.body).to include("RuntimeError")
    end

    it "renders Retry and Discard buttons" do
      create_failed
      get "#{engine_root}/failed_jobs"
      expect(response.body).to include("Retry")
      expect(response.body).to include("Discard")
    end
  end

  describe "DELETE /failed_jobs/:id" do
    context "with HTML format" do
      it "destroys the job and redirects" do
        execution = create_failed
        delete "#{engine_root}/failed_jobs/#{execution.id}"
        expect(response).to redirect_to("#{engine_root}/failed_jobs")
        expect(SolidQueue::FailedExecution.exists?(execution.id)).to be false
      end
    end

    context "with turbo_stream format" do
      it "returns a turbo stream response" do
        execution = create_failed
        delete "#{engine_root}/failed_jobs/#{execution.id}",
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /failed_jobs/:id/retry" do
    it "re-enqueues the job and redirects" do
      execution = create_failed
      post "#{engine_root}/failed_jobs/#{execution.id}/retry"
      expect(response).to redirect_to("#{engine_root}/failed_jobs")
      expect(SolidQueue::FailedExecution.exists?(execution.id)).to be false
    end
  end
end
