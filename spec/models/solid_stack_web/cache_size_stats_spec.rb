require "rails_helper"

RSpec.describe SolidStackWeb::CacheSizeStats do
  def create_entry(key:, value:)
    SolidCache::Entry.write(key, value)
  end

  describe "#total" do
    it "returns 0 when the cache is empty" do
      expect(described_class.new.total).to eq(0)
    end

    it "returns the count of all entries" do
      create_entry(key: "a", value: "x")
      create_entry(key: "b", value: "y")
      expect(described_class.new.total).to eq(2)
    end
  end

  describe "#top_entries" do
    it "returns entries ordered by byte_size descending" do
      create_entry(key: "small", value: "x")
      create_entry(key: "large", value: "x" * 500)
      keys = described_class.new.top_entries.map(&:key)
      expect(keys.first).to eq("large")
    end

    it "returns at most 10 entries" do
      15.times { |i| create_entry(key: "key#{i}", value: "v") }
      expect(described_class.new.top_entries.size).to eq(10)
    end
  end

  describe "#buckets" do
    it "returns one bucket per size range" do
      expect(described_class.new.buckets.size).to eq(SolidStackWeb::CacheSizeStats::BUCKETS.size)
    end

    it "counts entries in the correct size bucket" do
      create_entry(key: "tiny", value: "x")
      buckets = described_class.new.buckets
      small_bucket = buckets.find { |b| b[:label] == "< 1 KB" }
      expect(small_bucket[:count]).to eq(1)
    end

    it "returns zero counts when the cache is empty" do
      described_class.new.buckets.each do |b|
        expect(b[:count]).to eq(0)
      end
    end
  end
end
