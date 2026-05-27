require "rails_helper"

RSpec.describe "FailedJobErrors", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_failed(exception_class: "RuntimeError", message: "something went wrong", class_name: "FailingJob")
    SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
    job = SolidQueue::Job.create!(
      class_name:, queue_name: "default", priority: 0,
      arguments: { "executions" => 0, "exception_executions" => {} }
    )
    execution = SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class:, message:, backtrace: ["app/jobs/failing_job.rb:5"] }
    )
    SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
    execution
  end

  describe "GET /failed_jobs/errors" do
    it "returns 200" do
      get "#{engine_root}/failed_jobs/errors"
      expect(response).to have_http_status(:ok)
    end

    it "shows an empty state when there are no failed jobs" do
      get "#{engine_root}/failed_jobs/errors"
      expect(response.body).to include("No failed jobs")
    end

    it "groups jobs by exception class and shows the count" do
      2.times { create_failed(exception_class: "ArgumentError", message: "bad arg") }
      create_failed(exception_class: "RuntimeError", message: "boom")

      get "#{engine_root}/failed_jobs/errors"

      expect(response.body).to include("ArgumentError")
      expect(response.body).to include("RuntimeError")
      expect(response.body).to include("2")
    end

    it "shows the message prefix" do
      create_failed(exception_class: "ArgumentError", message: "wrong number of arguments")

      get "#{engine_root}/failed_jobs/errors"

      expect(response.body).to include("wrong number of arguments")
    end

    it "orders groups by count descending" do
      3.times { create_failed(exception_class: "ArgumentError") }
      create_failed(exception_class: "RuntimeError")

      get "#{engine_root}/failed_jobs/errors"

      argument_pos = response.body.index("ArgumentError")
      runtime_pos  = response.body.index("RuntimeError")
      expect(argument_pos).to be < runtime_pos
    end

    it "renders a View Jobs link for each error group" do
      create_failed(exception_class: "TimeoutError")

      get "#{engine_root}/failed_jobs/errors"

      expect(response.body).to include("View Jobs")
      expect(response.body).to include("error_class=TimeoutError")
    end

    it "includes a link back to the failed jobs list" do
      get "#{engine_root}/failed_jobs/errors"
      expect(response.body).to include("Failed Jobs")
    end
  end

  describe "GET /failed_jobs with error_class filter" do
    it "filters the list to the given error class" do
      create_failed(exception_class: "ArgumentError", class_name: "ArgJob")
      create_failed(exception_class: "RuntimeError",  class_name: "RuntimeJob")

      get "#{engine_root}/failed_jobs", params: { error_class: "ArgumentError" }

      expect(response.body).to include("ArgJob")
      expect(response.body).not_to include("RuntimeJob")
    end

    it "shows the active filter and a clear link" do
      create_failed(exception_class: "ArgumentError")

      get "#{engine_root}/failed_jobs", params: { error_class: "ArgumentError" }

      expect(response.body).to include("ArgumentError")
      expect(response.body).to include("Clear filter")
    end

    it "shows all jobs when no filter is set" do
      create_failed(exception_class: "ArgumentError", class_name: "ArgJob")
      create_failed(exception_class: "RuntimeError",  class_name: "RuntimeJob")

      get "#{engine_root}/failed_jobs"

      expect(response.body).to include("ArgJob")
      expect(response.body).to include("RuntimeJob")
    end

    it "skips executions with unparseable error data" do
      execution = create_failed(exception_class: "ArgumentError", class_name: "ArgJob")
      allow(::SolidQueue::FailedExecution).to receive(:pluck).and_return(
        [[execution.id, "not valid json {{{"]]
      )

      get "#{engine_root}/failed_jobs", params: { error_class: "ArgumentError" }

      expect(response).to have_http_status(:ok)
    end
  end
end
