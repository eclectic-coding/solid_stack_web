require "rails_helper"

RSpec.describe "CacheEntries", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_entry(key: "mykey", value: "myval")
    SolidCache::Entry.write(key, value)
    SolidCache::Entry.order(created_at: :desc).first
  end

  describe "GET /cache/entries" do
    it "returns 200" do
      get "#{engine_root}/cache/entries"
      expect(response).to have_http_status(:ok)
    end

    it "lists entries sorted by byte_size desc by default" do
      create_entry(key: "small", value: "x")
      create_entry(key: "large", value: "x" * 100)
      get "#{engine_root}/cache/entries"
      expect(response.body.index("large")).to be < response.body.index("small")
    end

    it "filters entries by key substring" do
      create_entry(key: "alpha:1", value: "a")
      create_entry(key: "beta:1", value: "b")
      get "#{engine_root}/cache/entries", params: { q: "alpha" }
      expect(response.body).to include("alpha:1")
      expect(response.body).not_to include("beta:1")
    end

    it "shows empty state when no entries exist" do
      get "#{engine_root}/cache/entries"
      expect(response.body).to include("No cache entries")
    end

    it "shows empty state when search yields no results" do
      create_entry(key: "some:key", value: "v")
      get "#{engine_root}/cache/entries", params: { q: "nope" }
      expect(response.body).to include("No entries matching")
    end

    it "sorts by created_at when requested" do
      get "#{engine_root}/cache/entries", params: { column: "created_at", direction: "asc" }
      expect(response).to have_http_status(:ok)
    end

    it "ignores invalid sort column and falls back to byte_size" do
      get "#{engine_root}/cache/entries", params: { column: "evil; DROP TABLE", direction: "desc" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /cache/entries/:id" do
    it "returns 200 and shows key metadata" do
      entry = create_entry(key: "detail:key", value: "hello")
      get "#{engine_root}/cache/entries/#{entry.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("detail:key")
      expect(response.body).to include("Bytes") # number_to_human_size
    end

    it "hides value when allow_value_preview is false" do
      entry = create_entry(key: "secret:key", value: "sensitive")
      allow(SolidStackWeb).to receive(:allow_value_preview).and_return(false)
      get "#{engine_root}/cache/entries/#{entry.id}"
      expect(response.body).to include("allow_value_preview")
      expect(response.body).not_to include("sensitive")
    end

    it "shows value when allow_value_preview is true" do
      entry = create_entry(key: "visible:key", value: "my_cached_value")
      allow(SolidStackWeb).to receive(:allow_value_preview).and_return(true)
      get "#{engine_root}/cache/entries/#{entry.id}"
      expect(response.body).to include("my_cached_value")
    end
  end

  describe "DELETE /cache/entries/:id" do
    it "deletes the entry and redirects" do
      entry = create_entry
      delete "#{engine_root}/cache/entries/#{entry.id}"
      expect(response).to redirect_to("#{engine_root}/cache/entries")
      expect(SolidCache::Entry.exists?(entry.id)).to be false
    end
  end

  describe "DELETE /cache/flush" do
    it "deletes all entries and redirects" do
      3.times { |i| create_entry(key: "key#{i}", value: "v") }
      delete "#{engine_root}/cache/flush"
      expect(response).to redirect_to("#{engine_root}/cache/entries")
      expect(SolidCache::Entry.count).to eq(0)
    end
  end

  describe "pagination" do
    it "shows pagination controls when entries exceed one page" do
      26.times { |i| create_entry(key: "key#{i}", value: "v") }

      get "#{engine_root}/cache/entries"

      expect(response.body).to include("page=2")
    end

    it "returns 200 for page 2" do
      26.times { |i| create_entry(key: "key#{i}", value: "v") }

      get "#{engine_root}/cache/entries", params: { page: 2 }

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for an out-of-range page" do
      create_entry

      get "#{engine_root}/cache/entries", params: { page: 999 }

      expect(response).to have_http_status(:ok)
    end
  end
end
