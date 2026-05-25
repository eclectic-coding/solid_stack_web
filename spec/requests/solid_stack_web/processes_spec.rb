require "rails_helper"

RSpec.describe "Processes", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_process(kind: "Worker", name: "worker-1")
    SolidQueue::Process.create!(
      kind:, name:, pid: rand(10_000..99_999),
      hostname: "localhost", last_heartbeat_at: Time.current
    )
  end

  describe "GET /processes" do
    it "returns 200" do
      get "#{engine_root}/processes"
      expect(response).to have_http_status(:ok)
    end

    it "shows an empty state when no processes are running" do
      get "#{engine_root}/processes"
      expect(response.body).to include("No active processes")
    end

    it "lists running processes" do
      create_process(kind: "Worker", name: "worker-1")
      get "#{engine_root}/processes"
      expect(response.body).to include("Worker")
      expect(response.body).to include("worker-1")
    end

    it "shows multiple processes" do
      create_process(kind: "Worker",     name: "worker-1")
      create_process(kind: "Dispatcher", name: "dispatcher-1")
      get "#{engine_root}/processes"
      expect(response.body).to include("Worker")
      expect(response.body).to include("Dispatcher")
    end
  end
end
