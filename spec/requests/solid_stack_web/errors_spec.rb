require "rails_helper"

RSpec.describe "Error pages", type: :request do
  let(:engine_root) { "/solid_stack" }

  describe "404 Not Found" do
    it "renders the engine 404 page when a record is not found" do
      get "#{engine_root}/jobs/99999999"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Not Found")
      expect(response.body).to include("404")
    end

    it "renders within the dashboard chrome" do
      get "#{engine_root}/jobs/99999999"
      expect(response.body).to include("sqw-header")
      expect(response.body).to include("Back to Dashboard")
    end
  end

  describe "500 Internal Server Error" do
    before do
      allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)
      allow_any_instance_of(SolidStackWeb::JobsController).to receive(:index).and_raise(StandardError, "test error")
    end

    it "renders the engine 500 page on an unhandled error" do
      get "#{engine_root}/jobs"
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Something Went Wrong")
      expect(response.body).to include("500")
    end

    it "renders within the dashboard chrome" do
      get "#{engine_root}/jobs"
      expect(response.body).to include("sqw-header")
      expect(response.body).to include("Back to Dashboard")
    end
  end
end
