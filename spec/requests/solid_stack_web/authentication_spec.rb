require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:engine_root) { "/solid_stack" }

  around do |example|
    original = SolidStackWeb.authenticate
    example.run
  ensure
    SolidStackWeb.instance_variable_set(:@authenticate, original)
  end

  context "when the auth block returns truthy" do
    it "allows the request through" do
      SolidStackWeb.authenticate { true }

      get "#{engine_root}/jobs"

      expect(response).to have_http_status(:ok)
    end
  end

  context "when the auth block returns falsy" do
    it "falls back to HTTP Basic auth and returns 401" do
      SolidStackWeb.authenticate { false }

      get "#{engine_root}/jobs"

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to include("Basic")
    end
  end
end