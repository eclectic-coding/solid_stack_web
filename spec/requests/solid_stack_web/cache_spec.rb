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

    it "hides size distribution sections when cache is empty" do
      SolidCache::Entry.delete_all
      get "#{engine_root}/cache"
      expect(response.body).not_to include("Size Distribution")
      expect(response.body).not_to include("Largest Entries")
    end

    it "shows size distribution and largest entries when entries exist" do
      SolidCache::Entry.write("small:key", "x")
      SolidCache::Entry.write("large:key", "x" * 2000)
      get "#{engine_root}/cache"
      expect(response.body).to include("Size Distribution")
      expect(response.body).to include("Largest Entries")
    end

    it "shows all size bucket labels" do
      SolidCache::Entry.write("bucket:key", "hello")
      get "#{engine_root}/cache"
      expect(response.body).to include("&lt; 1 KB")
      expect(response.body).to include("&gt; 1 MB")
    end

    it "links largest entries to their detail pages" do
      SolidCache::Entry.write("linked:key", "value")
      get "#{engine_root}/cache"
      expect(response.body).to include("linked:key")
      expect(response.body).to include("cache/entries")
    end
  end
end
