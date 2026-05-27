require "rails_helper"

RSpec.describe "Stats", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_finished(class_name: "MyJob", duration: 10)
    SolidQueue::Job.create!(
      class_name:,
      queue_name: "default",
      priority:   0,
      created_at: duration.seconds.ago,
      finished_at: Time.current
    )
  end

  describe "GET /stats" do
    it "returns 200" do
      get "#{engine_root}/stats"
      expect(response).to have_http_status(:ok)
    end

    it "shows an empty state when no finished jobs exist" do
      get "#{engine_root}/stats"
      expect(response.body).to include("No finished jobs")
    end

    it "aggregates finished jobs by class name" do
      3.times { create_finished(class_name: "SlowJob", duration: 30) }
      create_finished(class_name: "FastJob", duration: 1)
      get "#{engine_root}/stats"
      expect(response.body).to include("SlowJob")
      expect(response.body).to include("FastJob")
    end

    it "does not include unfinished jobs" do
      SolidQueue::Job.create!(class_name: "PendingJob", queue_name: "default", priority: 0)
      get "#{engine_root}/stats"
      expect(response.body).not_to include("PendingJob")
    end

    it "defaults to sorting by p95 descending" do
      create_finished(class_name: "MyJob")
      get "#{engine_root}/stats"
      expect(response.body).to include("p95")
    end

    it "accepts a sort param" do
      create_finished(class_name: "MyJob")
      get "#{engine_root}/stats", params: { sort: "count", direction: "asc" }
      expect(response).to have_http_status(:ok)
    end

    it "ignores invalid sort params" do
      get "#{engine_root}/stats", params: { sort: "DROP TABLE", direction: "evil" }
      expect(response).to have_http_status(:ok)
    end

    it "shows formatted durations" do
      create_finished(class_name: "MyJob", duration: 10)
      get "#{engine_root}/stats"
      expect(response.body).to match(/\d+(\.\d+)?s|ms/)
    end

    it "renders p99 and Std Dev column headers" do
      create_finished(class_name: "MyJob")
      get "#{engine_root}/stats"
      expect(response.body).to include("p99")
      expect(response.body).to include("Std Dev")
    end

    it "accepts sort by p99" do
      create_finished(class_name: "MyJob")
      get "#{engine_root}/stats", params: { sort: "p99", direction: "desc" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts sort by stddev" do
      create_finished(class_name: "MyJob")
      get "#{engine_root}/stats", params: { sort: "stddev", direction: "desc" }
      expect(response).to have_http_status(:ok)
    end
  end
end
