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
