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

  describe "GET /failed_jobs.csv" do
    it "returns a CSV attachment" do
      get "#{engine_root}/failed_jobs.csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include(".csv")
    end

    it "includes the correct headers" do
      get "#{engine_root}/failed_jobs.csv"

      headers = response.body.lines.first.chomp
      expect(headers).to eq("id,class_name,queue_name,error_class,error_message,failed_at")
    end

    it "includes one row per failed job with error details" do
      create_failed(class_name: "BrokenJob")

      get "#{engine_root}/failed_jobs.csv"

      rows = CSV.parse(response.body, headers: true)
      expect(rows.length).to eq(1)
      expect(rows.first["class_name"]).to eq("BrokenJob")
      expect(rows.first["error_class"]).to eq("RuntimeError")
      expect(rows.first["error_message"]).to eq("something went wrong")
    end
  end

  describe "GET /failed_jobs/:id" do
    it "returns 200 and shows the job class" do
      execution = create_failed(class_name: "BrokenJob")
      get "#{engine_root}/failed_jobs/#{execution.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("BrokenJob")
    end

    it "shows the error class and message" do
      execution = create_failed
      get "#{engine_root}/failed_jobs/#{execution.id}"
      expect(response.body).to include("RuntimeError")
      expect(response.body).to include("something went wrong")
    end

    it "shows a breadcrumb back to failed jobs" do
      execution = create_failed
      get "#{engine_root}/failed_jobs/#{execution.id}"
      expect(response.body).to include("sqw-breadcrumb")
      expect(response.body).to include("Failed Jobs")
    end

    it "renders the argument editor form" do
      execution = create_failed
      get "#{engine_root}/failed_jobs/#{execution.id}"
      expect(response.body).to include("sqw-code-input")
      expect(response.body).to include("Update")
    end

    it "shows Retry and Discard buttons" do
      execution = create_failed
      get "#{engine_root}/failed_jobs/#{execution.id}"
      expect(response.body).to include("Retry")
      expect(response.body).to include("Discard")
    end

    it "falls back to raw arguments string when JSON generation fails" do
      execution = create_failed
      job_args  = execution.job.arguments
      allow(JSON).to receive(:pretty_generate).and_wrap_original do |m, obj, *rest|
        raise JSON::GeneratorError, "NaN" if obj == job_args
        m.call(obj, *rest)
      end

      get "#{engine_root}/failed_jobs/#{execution.id}"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /failed_jobs/:id/arguments" do
    it "updates arguments and retries the job" do
      execution = create_failed
      new_args = { "executions" => 0, "exception_executions" => {}, "user_id" => 99 }.to_json

      patch "#{engine_root}/failed_jobs/#{execution.id}/arguments",
            params: { arguments: new_args }

      expect(SolidQueue::FailedExecution.exists?(execution.id)).to be false
      expect(response).to redirect_to("#{engine_root}/failed_jobs")
    end

    it "redirects back with alert on invalid JSON" do
      execution = create_failed

      patch "#{engine_root}/failed_jobs/#{execution.id}/arguments",
            params: { arguments: "not valid json {{" }

      expect(SolidQueue::FailedExecution.exists?(execution.id)).to be true
      expect(response).to redirect_to("#{engine_root}/failed_jobs/#{execution.id}")
    end

    it "redirects with alert when update raises" do
      execution = create_failed
      allow_any_instance_of(SolidQueue::Job).to receive(:update!).and_raise(RuntimeError, "db error")

      patch "#{engine_root}/failed_jobs/#{execution.id}/arguments",
            params: { arguments: { "executions" => 0, "exception_executions" => {} }.to_json }

      expect(response).to redirect_to("#{engine_root}/failed_jobs")
      expect(flash[:alert]).to eq("Could not update job: db error")
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
