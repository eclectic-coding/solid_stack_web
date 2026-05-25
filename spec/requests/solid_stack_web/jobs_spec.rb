require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_ready(class_name: "MyJob", queue_name: "default", priority: 0)
    SolidQueue::Job.create!(class_name:, queue_name:, priority:)
  end

  describe "GET /jobs" do
    it "returns 200" do
      get "#{engine_root}/jobs"
      expect(response).to have_http_status(:ok)
    end

    it "defaults to ready status" do
      get "#{engine_root}/jobs"
      expect(response.body).to include("sqw-tab--active")
    end

    it "shows ready jobs" do
      create_ready(class_name: "ReportJob")
      get "#{engine_root}/jobs"
      expect(response.body).to include("ReportJob")
    end

    it "renders the filter form" do
      get "#{engine_root}/jobs"
      expect(response.body).to include('name="q"')
      expect(response.body).to include("sqw-period-filter")
    end
  end

  describe "GET /jobs?q=" do
    it "returns only jobs whose class name matches the substring" do
      create_ready(class_name: "ReportJob")
      create_ready(class_name: "CleanupJob")

      get "#{engine_root}/jobs", params: { q: "Report" }

      expect(response.body).to     include("ReportJob")
      expect(response.body).not_to include("CleanupJob")
    end

    it "is case-insensitive on SQLite" do
      create_ready(class_name: "ReportJob")

      get "#{engine_root}/jobs", params: { q: "report" }

      expect(response.body).to include("ReportJob")
    end

    it "returns all jobs when q is blank" do
      create_ready(class_name: "ReportJob")
      create_ready(class_name: "CleanupJob")

      get "#{engine_root}/jobs", params: { q: "" }

      expect(response.body).to include("ReportJob")
      expect(response.body).to include("CleanupJob")
    end
  end

  describe "GET /jobs?queue=" do
    it "returns only jobs in the specified queue" do
      create_ready(class_name: "ReportJob",  queue_name: "reports")
      create_ready(class_name: "CleanupJob", queue_name: "maintenance")

      get "#{engine_root}/jobs", params: { queue: "reports" }

      expect(response.body).to     include("ReportJob")
      expect(response.body).not_to include("CleanupJob")
    end

    it "shows the queue select when multiple queues exist" do
      create_ready(queue_name: "alpha")
      create_ready(queue_name: "beta")

      get "#{engine_root}/jobs"

      expect(response.body).to include('name="queue"')
    end

    it "does not show the queue select when only one queue exists" do
      create_ready(queue_name: "default")

      get "#{engine_root}/jobs"

      expect(response.body).not_to include('name="queue"')
    end
  end

  describe "GET /jobs?priority=" do
    it "returns only jobs with the specified priority" do
      create_ready(class_name: "HighPriJob", priority: 0)
      create_ready(class_name: "LowPriJob",  priority: 10)

      get "#{engine_root}/jobs", params: { priority: "10" }

      expect(response.body).to     include("LowPriJob")
      expect(response.body).not_to include("HighPriJob")
    end
  end

  describe "GET /jobs?period=" do
    it "returns only jobs enqueued within the given period" do
      old_job = create_ready(class_name: "OldJob")
      old_job.ready_execution.update_columns(created_at: 2.days.ago)
      old_job.update_columns(created_at: 2.days.ago)

      create_ready(class_name: "NewJob")

      get "#{engine_root}/jobs", params: { period: "1h" }

      expect(response.body).to     include("NewJob")
      expect(response.body).not_to include("OldJob")
    end

    it "returns all jobs when no period is specified" do
      old_job = create_ready(class_name: "OldJob")
      old_job.ready_execution.update_columns(created_at: 2.days.ago)
      old_job.update_columns(created_at: 2.days.ago)

      create_ready(class_name: "NewJob")

      get "#{engine_root}/jobs"

      expect(response.body).to include("OldJob")
      expect(response.body).to include("NewJob")
    end
  end

  describe "GET /jobs/:id" do
    it "returns 200 and shows the job class" do
      job = create_ready(class_name: "ReportJob")
      get "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ReportJob")
    end

    it "shows queue and priority" do
      job = create_ready(queue_name: "critical", priority: 5)
      get "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

      expect(response.body).to include("critical")
      expect(response.body).to include("5")
    end

    it "pretty-prints JSON arguments" do
      job = SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default", priority: 0,
                                    arguments: [{ user_id: 42 }].to_json)
      get "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

      expect(response.body).to include("user_id")
      expect(response.body).to include("42")
    end

    it "shows a discard button for ready jobs" do
      job = create_ready
      get "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

      expect(response.body).to include("Discard Job")
    end

    it "does not show a discard button for claimed jobs" do
      SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
      job = SolidQueue::Job.create!(class_name: "WorkJob", queue_name: "default", priority: 0)
      process = SolidQueue::Process.create!(
        kind: "Worker", name: "worker-spec", pid: 99_999,
        hostname: "test", last_heartbeat_at: Time.current
      )
      execution = SolidQueue::ClaimedExecution.create!(job: job, process_id: process.id)
      SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)

      get "#{engine_root}/jobs/#{execution.id}", params: { status: "claimed" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Discard Job")
    end

    it "shows a breadcrumb link to the jobs list" do
      job = create_ready
      get "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

      expect(response.body).to include("sqw-breadcrumb")
      expect(response.body).to include("Jobs")
    end
  end

  describe "DELETE /jobs/:id" do
    context "with HTML format" do
      it "destroys the job and redirects to the jobs list" do
        job = create_ready
        delete "#{engine_root}/jobs/#{job.ready_execution.id}", params: { status: "ready" }

        expect(response).to redirect_to("#{engine_root}/jobs?status=ready")
        expect(SolidQueue::Job.exists?(job.id)).to be false
      end

      it "preserves filter params in the redirect" do
        job = create_ready(queue_name: "reports")
        delete "#{engine_root}/jobs/#{job.ready_execution.id}",
               params: { status: "ready", queue: "reports", q: "Report", period: "1h" }

        expect(response.location).to include("queue=reports")
        expect(response.location).to include("q=Report")
        expect(response.location).to include("period=1h")
      end
    end

    context "with turbo_stream format" do
      it "removes the row when other jobs remain" do
        job1 = create_ready
        create_ready

        delete "#{engine_root}/jobs/#{job1.ready_execution.id}",
               params: { status: "ready" },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("execution_#{job1.ready_execution.id}")
        expect(response.body).to include("remove")
      end

      it "replaces the table with empty state when it was the last job" do
        job = create_ready

        delete "#{engine_root}/jobs/#{job.ready_execution.id}",
               params: { status: "ready" },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("sqw-jobs-table")
        expect(response.body).to include("replace")
      end
    end

    it "returns 422 when status is not discardable" do
      SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
      job = SolidQueue::Job.create!(class_name: "WorkJob", queue_name: "default", priority: 0)
      process = SolidQueue::Process.create!(
        kind: "Worker", name: "worker-spec-del", pid: 88_888,
        hostname: "test", last_heartbeat_at: Time.current
      )
      execution = SolidQueue::ClaimedExecution.create!(job: job, process_id: process.id)
      SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)

      delete "#{engine_root}/jobs/#{execution.id}", params: { status: "claimed" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "combined filters" do
    it "applies class and queue filters together" do
      create_ready(class_name: "ReportJob",  queue_name: "reports")
      create_ready(class_name: "CleanupJob", queue_name: "reports")
      create_ready(class_name: "ReportJob",  queue_name: "default")

      get "#{engine_root}/jobs", params: { q: "Report", queue: "reports" }

      expect(response.body).to     include("ReportJob")
      expect(response.body).not_to include("CleanupJob")
      # The default-queue ReportJob should be excluded — only one match in the reports queue
      expect(response.body.scan("ReportJob").length).to eq(1)
    end
  end

  describe "filter persistence across tabs" do
    it "preserves q param in tab links" do
      get "#{engine_root}/jobs", params: { q: "Report" }

      expect(response.body).to include("q=Report")
    end

    it "preserves period param in tab links" do
      get "#{engine_root}/jobs", params: { period: "24h" }

      expect(response.body).to include("period=24h")
    end
  end
end
