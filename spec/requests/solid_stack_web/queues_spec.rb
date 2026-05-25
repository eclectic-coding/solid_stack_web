require "rails_helper"

RSpec.describe "Queues", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_ready(queue_name: "default")
    SolidQueue::Job.create!(class_name: "MyJob", queue_name:, priority: 0)
  end

  describe "GET /queues" do
    it "returns 200" do
      get "#{engine_root}/queues"
      expect(response).to have_http_status(:ok)
    end

    it "lists distinct queue names" do
      create_ready(queue_name: "alpha")
      create_ready(queue_name: "beta")
      get "#{engine_root}/queues"
      expect(response.body).to include("alpha")
      expect(response.body).to include("beta")
    end

    it "shows the ready job count per queue" do
      2.times { create_ready(queue_name: "reports") }
      get "#{engine_root}/queues"
      expect(response.body).to include("reports")
    end

    it "shows paused state for paused queues" do
      create_ready(queue_name: "low")
      SolidQueue::Pause.create!(queue_name: "low")
      get "#{engine_root}/queues"
      expect(response.body).to include("Paused")
    end
  end

  describe "POST /queues/:id/pause" do
    it "pauses the queue and redirects" do
      create_ready(queue_name: "default")
      post "#{engine_root}/queues/default/pause"
      expect(response).to redirect_to("#{engine_root}/queues")
      expect(SolidQueue::Pause.exists?(queue_name: "default")).to be true
    end

    it "is idempotent when the queue is already paused" do
      SolidQueue::Pause.create!(queue_name: "default")
      expect { post "#{engine_root}/queues/default/pause" }.not_to raise_error
      expect(response).to redirect_to("#{engine_root}/queues")
    end
  end

  describe "DELETE /queues/:id/resume" do
    it "resumes a paused queue and redirects" do
      SolidQueue::Pause.create!(queue_name: "default")
      delete "#{engine_root}/queues/default/resume"
      expect(response).to redirect_to("#{engine_root}/queues")
      expect(SolidQueue::Pause.exists?(queue_name: "default")).to be false
    end

    it "is a no-op when the queue is not paused" do
      expect { delete "#{engine_root}/queues/default/resume" }.not_to raise_error
      expect(response).to redirect_to("#{engine_root}/queues")
    end
  end
end
