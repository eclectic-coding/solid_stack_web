require "rails_helper"

RSpec.describe "Audit log", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_event(action: "job_discarded", actor: nil, job_class: "MyJob", queue_name: "default", item_count: 1)
    SolidStackWeb::AuditEvent.create!(
      action: action, actor: actor, job_class: job_class,
      queue_name: queue_name, item_count: item_count
    )
  end

  describe "GET /audit" do
    it "returns 200" do
      get "#{engine_root}/audit"
      expect(response).to have_http_status(:ok)
    end

    it "shows the page heading" do
      get "#{engine_root}/audit"
      expect(response.body).to include("Audit Log")
    end

    it "shows empty state when no events exist" do
      get "#{engine_root}/audit"
      expect(response.body).to include("No audit events recorded yet")
    end

    it "renders a row for each audit event" do
      create_event(action: "queue_paused", queue_name: "critical")
      create_event(action: "failed_job_retried", job_class: "BillingJob")

      get "#{engine_root}/audit"

      expect(response.body).to include("queue paused")
      expect(response.body).to include("failed job retried")
    end

    it "renders the action as a badge" do
      create_event(action: "job_discarded")
      get "#{engine_root}/audit"
      expect(response.body).to include("sqw-badge--failed")
    end

    it "shows actor as a filter link when present" do
      create_event(actor: "admin@example.com")
      get "#{engine_root}/audit"
      expect(response.body).to include("admin@example.com")
    end

    it "shows a dash when actor is nil" do
      create_event(actor: nil)
      get "#{engine_root}/audit"
      expect(response.body).to include("—")
    end
  end

  describe "GET /audit?audit_action=" do
    it "filters events by action" do
      create_event(action: "job_discarded", job_class: "DiscardedJob")
      create_event(action: "queue_paused",  queue_name: "unique-queue-xyz")

      get "#{engine_root}/audit", params: { audit_action: "job_discarded" }

      expect(response.body).to     include("DiscardedJob")
      expect(response.body).not_to include("unique-queue-xyz")
    end

    it "ignores invalid action values" do
      get "#{engine_root}/audit", params: { audit_action: "drop_table--users" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /audit?actor=" do
    it "filters events by actor" do
      create_event(actor: "alice@example.com", job_class: "AliceJob")
      create_event(actor: "bob@example.com",   job_class: "BobJob")

      get "#{engine_root}/audit", params: { actor: "alice@example.com" }

      expect(response.body).to     include("AliceJob")
      expect(response.body).not_to include("BobJob")
    end
  end

  describe "GET /audit?queue=" do
    it "filters events by queue" do
      create_event(queue_name: "critical", job_class: "CriticalJob")
      create_event(queue_name: "default",  job_class: "DefaultJob")

      get "#{engine_root}/audit", params: { queue: "critical" }

      expect(response.body).to     include("CriticalJob")
      expect(response.body).not_to include("DefaultJob")
    end
  end

  describe "GET /audit.csv" do
    it "returns a CSV attachment" do
      get "#{engine_root}/audit.csv"
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes the correct headers" do
      get "#{engine_root}/audit.csv"
      headers = response.body.lines.first.chomp
      expect(headers).to eq("id,action,actor,job_class,queue_name,item_count,created_at")
    end

    it "includes one row per event" do
      create_event(action: "job_discarded",  job_class: "AlphaJob")
      create_event(action: "queue_paused",   job_class: nil)

      get "#{engine_root}/audit.csv"
      rows = CSV.parse(response.body, headers: true)
      expect(rows.length).to eq(2)
    end

    it "applies active filters to the export" do
      create_event(action: "job_discarded",  job_class: "AlphaJob")
      create_event(action: "queue_paused",   job_class: nil)

      get "#{engine_root}/audit.csv", params: { audit_action: "job_discarded" }
      rows = CSV.parse(response.body, headers: true)
      expect(rows.length).to eq(1)
      expect(rows.first["action"]).to eq("job_discarded")
    end
  end

  describe "audit recording" do
    it "records a job_discarded event when a ready job is discarded" do
      job = SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")

      expect {
        delete "#{engine_root}/jobs/#{job.ready_execution.id}",
               params: { status: "ready" }
      }.to change(SolidStackWeb::AuditEvent, :count).by(1)

      event = SolidStackWeb::AuditEvent.last
      expect(event.action).to eq("job_discarded")
      expect(event.job_class).to eq("MyJob")
      expect(event.queue_name).to eq("default")
    end

    it "records a queue_paused event" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")

      expect {
        post "#{engine_root}/queues/default/pause"
      }.to change(SolidStackWeb::AuditEvent, :count).by(1)

      expect(SolidStackWeb::AuditEvent.last.action).to eq("queue_paused")
      expect(SolidStackWeb::AuditEvent.last.queue_name).to eq("default")
    end
  end
end
