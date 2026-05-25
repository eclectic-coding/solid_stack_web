require "rails_helper"

RSpec.describe "Cache", type: :request do
  let(:engine_root) { "/solid_stack" }

  describe "GET /cache" do
    it "returns 200" do
      get "#{engine_root}/cache"
      expect(response).to have_http_status(:ok)
    end

    it "shows zero counts when no entries exist" do
      get "#{engine_root}/cache"
      expect(response.body).to include("Total Entries")
      expect(response.body).to include("Total Size")
    end

    it "reflects live entry count" do
      SolidCache::Entry.write("key1", "value1")
      SolidCache::Entry.write("key2", "value2")

      get "#{engine_root}/cache"

      expect(response.body).to match(/class="sqw-stat__value">\s*2\s*</)
    end

    it "shows human-readable total size" do
      SolidCache::Entry.write("sizekey", "hello")

      get "#{engine_root}/cache"

      expect(response.body).to include("Bytes").or include("KB").or include("MB")
    end
  end
end