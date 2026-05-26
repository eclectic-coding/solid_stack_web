require "rails_helper"

RSpec.describe "History", type: :request do
  let(:engine_root) { "/solid_stack" }

  def finished_job(class_name: "TestJob", queue_name: "default", duration: 30, finished_at: 5.minutes.ago)
    job = SolidQueue::Job.new(
      queue_name:, class_name:, priority: 0,
      arguments: { "executions" => 0, "exception_executions" => {} },
      active_job_id: SecureRandom.uuid
    )
    job.finished_at = finished_at
    job.created_at  = finished_at - duration.seconds
    job.updated_at  = finished_at
    job.save!(validate: false)
    job
  end

  describe "GET /history" do
    it "returns 200" do
      get "#{engine_root}/history"
      expect(response).to have_http_status(:ok)
    end

    it "shows the page title" do
      get "#{engine_root}/history"
      expect(response.body).to include("Job History")
    end

    it "displays finished jobs" do
      finished_job(class_name: "ReportGeneratorJob")
      get "#{engine_root}/history"
      expect(response.body).to include("ReportGeneratorJob")
    end

    it "shows an empty state when no finished jobs exist" do
      get "#{engine_root}/history"
      expect(response.body).to include("No finished jobs yet")
    end

    it "displays class name, queue, duration, and finished_at columns" do
      finished_job(class_name: "InvoiceJob", queue_name: "critical", duration: 45)
      get "#{engine_root}/history"
      expect(response.body).to include("InvoiceJob")
      expect(response.body).to include("critical")
      expect(response.body).to include("45s")
    end

    it "shows History as active in the subnav" do
      get "#{engine_root}/history"
      expect(response.body).to include("sqw-subnav__link--active")
    end
  end

  describe "GET /history?period=" do
    it "filters to jobs finished within the period" do
      finished_job(class_name: "RecentJob", finished_at: 30.minutes.ago)
      finished_job(class_name: "OldJob",    finished_at: 48.hours.ago)

      get "#{engine_root}/history", params: { period: "1h" }

      expect(response.body).to     include("RecentJob")
      expect(response.body).not_to include("OldJob")
    end

    it "ignores invalid period values and shows all jobs" do
      finished_job(class_name: "AnyJob")

      get "#{engine_root}/history", params: { period: "bogus" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AnyJob")
    end
  end

  describe "GET /history?queue=" do
    it "filters by queue name" do
      finished_job(class_name: "CriticalJob", queue_name: "critical")
      finished_job(class_name: "DefaultJob",  queue_name: "default")

      get "#{engine_root}/history", params: { queue: "critical" }

      expect(response.body).to     include("CriticalJob")
      expect(response.body).not_to include("DefaultJob")
    end

    it "shows the active queue filter" do
      get "#{engine_root}/history", params: { queue: "critical" }
      expect(response.body).to include("Filtering by queue")
      expect(response.body).to include("critical")
    end
  end

  describe "GET /history?q=" do
    it "filters by class name substring" do
      finished_job(class_name: "InvoiceGeneratorJob")
      finished_job(class_name: "CleanupJob")

      get "#{engine_root}/history", params: { q: "Invoice" }

      expect(response.body).to     include("InvoiceGeneratorJob")
      expect(response.body).not_to include("CleanupJob")
    end
  end

  describe "GET /history.csv" do
    it "returns a CSV attachment" do
      get "#{engine_root}/history.csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include(".csv")
    end

    it "includes the correct headers" do
      get "#{engine_root}/history.csv"

      headers = response.body.lines.first.chomp
      expect(headers).to eq("id,class_name,queue_name,duration_seconds,finished_at")
    end

    it "includes one row per finished job" do
      finished_job(class_name: "ExportJob", queue_name: "default", duration: 12)

      get "#{engine_root}/history.csv"

      rows = CSV.parse(response.body, headers: true)
      expect(rows.length).to eq(1)
      expect(rows.first["class_name"]).to eq("ExportJob")
      expect(rows.first["duration_seconds"]).to eq("12")
    end
  end
end
