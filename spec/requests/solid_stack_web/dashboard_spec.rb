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
  end
end
