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
  end
end
