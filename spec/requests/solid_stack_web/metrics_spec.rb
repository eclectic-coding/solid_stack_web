require "rails_helper"

RSpec.describe "Metrics", type: :request do
  let(:engine_root) { "/solid_stack" }

  describe "GET /metrics" do
    it "returns 200 with JSON content type" do
      get "#{engine_root}/metrics", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end

    it "includes queue, cache, cable sections and generated_at" do
      get "#{engine_root}/metrics"
      payload = JSON.parse(response.body)
      expect(payload.keys).to contain_exactly("queue", "cache", "cable", "generated_at")
    end

    it "includes all queue status keys" do
      get "#{engine_root}/metrics"
      queue = JSON.parse(response.body)["queue"]
      expect(queue.keys).to include("ready", "scheduled", "claimed", "blocked", "failed",
                                    "done_1h", "done_24h", "processes_healthy", "processes_stale")
    end

    it "includes cache keys" do
      get "#{engine_root}/metrics"
      cache = JSON.parse(response.body)["cache"]
      expect(cache.keys).to contain_exactly("entries", "byte_size", "oldest_entry")
    end

    it "includes oldest_entry as ISO 8601 when entries exist" do
      SolidCache::Entry.write("metrics:key", "v")
      get "#{engine_root}/metrics"
      cache = JSON.parse(response.body)["cache"]
      expect(cache["oldest_entry"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it "includes oldest_entry as null when no entries exist" do
      SolidCache::Entry.delete_all
      get "#{engine_root}/metrics"
      cache = JSON.parse(response.body)["cache"]
      expect(cache["oldest_entry"]).to be_nil
    end

    it "includes cable keys" do
      get "#{engine_root}/metrics"
      cable = JSON.parse(response.body)["cable"]
      expect(cable.keys).to contain_exactly("messages", "channels")
    end

    it "reflects live job counts" do
      SolidQueue::ReadyExecution.joins(:job).delete_all
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")

      get "#{engine_root}/metrics"
      queue = JSON.parse(response.body)["queue"]
      expect(queue["ready"]).to eq(1)
    end

    it "includes slow_jobs key when threshold is configured" do
      SolidStackWeb.slow_job_threshold = 5
      get "#{engine_root}/metrics"
      queue = JSON.parse(response.body)["queue"]
      expect(queue).to have_key("slow_jobs")
    ensure
      SolidStackWeb.slow_job_threshold = nil
    end

    it "omits slow_jobs key when threshold is not configured" do
      get "#{engine_root}/metrics"
      queue = JSON.parse(response.body)["queue"]
      expect(queue).not_to have_key("slow_jobs")
    end
  end
end
