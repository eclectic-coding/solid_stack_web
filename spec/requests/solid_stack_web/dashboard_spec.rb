require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:engine_root) { "/solid_stack" }

  describe "GET /" do
    it "returns 200" do
      get engine_root
      expect(response).to have_http_status(:ok)
    end

    it "renders all three gem sections" do
      get engine_root
      expect(response.body).to include("Solid Queue")
      expect(response.body).to include("Solid Cache")
      expect(response.body).to include("Solid Cable")
    end

    it "links through to each gem section" do
      get engine_root
      expect(response.body).to include("View Jobs")
      expect(response.body).to include("View Cache")
      expect(response.body).to include("View Cable")
    end

    it "shows all queue status stats" do
      get engine_root
      %w[ready scheduled claimed blocked failed].each do |status|
        expect(response.body).to include("sqw-inline-stat--#{status}")
      end
    end

    it "reflects live job counts" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")

      get engine_root

      expect(response.body).to match(/class="sqw-inline-stat__value">\s*1\s*</)
    end

    it "shows done (1h) and done (24h) stats" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default",
                              finished_at: 30.minutes.ago)
      get engine_root
      expect(response.body).to include("Done (1h)")
      expect(response.body).to include("Done (24h)")
    end

    it "shows healthy process count" do
      get engine_root
      expect(response.body).to include("Healthy")
    end

    it "shows stale process count when stale processes exist" do
      SolidQueue::Process.create!(name: "stale-worker", kind: "Worker",
                                  hostname: "host", pid: 1,
                                  last_heartbeat_at: 10.minutes.ago)
      get engine_root
      expect(response.body).to include("Stale")
    end

    it "does not show slow jobs stat when threshold is not configured" do
      get engine_root
      expect(response.body).not_to include("Slow (24h)")
    end

    it "renders the throughput sparkline SVG" do
      get engine_root
      expect(response.body).to include("sqw-sparkline")
      expect(response.body).to include("Throughput")
    end

    it "renders a sparkline bar for a finished job" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default",
                              finished_at: 1.hour.ago)
      get engine_root
      expect(response.body).to include("<rect")
    end

    it "shows slow jobs stat when threshold is configured" do
      SolidStackWeb.slow_job_threshold = 5
      SolidQueue::Job.create!(class_name: "SlowJob", queue_name: "default",
                              created_at: 1.hour.ago, finished_at: 10.minutes.ago)
      get engine_root
      expect(response.body).to include("Slow (24h)")
    ensure
      SolidStackWeb.slow_job_threshold = nil
    end

    it "shows oldest cache entry age when entries exist" do
      SolidCache::Entry.write("dashboard:key", "v")
      get engine_root
      expect(response.body).to include("Oldest")
    end

    it "omits oldest cache entry stat when no entries exist" do
      SolidCache::Entry.delete_all
      get engine_root
      expect(response.body).not_to include("Oldest")
    end
  end

  describe "custom dashboard cards" do
    after { SolidStackWeb.dashboard_cards = nil }

    it "renders no custom cards by default" do
      get engine_root
      expect(response.body).not_to include('class="sqw-gem-card sqw-gem-card--custom"')
    end

    it "renders a configured custom card" do
      SolidStackWeb.dashboard_cards = [{ title: "My App" }]
      get engine_root
      expect(response.body).to include('class="sqw-gem-card sqw-gem-card--custom"')
      expect(response.body).to include("My App")
    end

    it "renders the optional header link" do
      SolidStackWeb.dashboard_cards = [{ title: "My App", link: { label: "View Admin", url: "/admin" } }]
      get engine_root
      expect(response.body).to include("View Admin")
      expect(response.body).to include("/admin")
    end

    it "renders stats returned by the stats lambda" do
      SolidStackWeb.dashboard_cards = [{ title: "My App", stats: -> { { "Users" => 42, "Premium" => 7 } } }]
      get engine_root
      expect(response.body).to include("Users")
      expect(response.body).to include("42")
      expect(response.body).to include("Premium")
      expect(response.body).to include("7")
    end

    it "renders multiple custom cards" do
      SolidStackWeb.dashboard_cards = [{ title: "App One" }, { title: "App Two" }]
      get engine_root
      expect(response.body).to include("App One")
      expect(response.body).to include("App Two")
    end
  end
end
