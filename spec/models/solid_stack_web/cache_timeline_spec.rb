require "rails_helper"

RSpec.describe SolidStackWeb::CacheTimeline do
  def create_entry(key:, value:, created_at: Time.current)
    SolidCache::Entry.write(key, value)
    SolidCache::Entry.order(created_at: :desc).first.tap do |e|
      e.update_columns(created_at: created_at)
    end
  end

  describe "#entry_buckets" do
    it "returns 24 buckets" do
      expect(described_class.new.entry_buckets.size).to eq(24)
    end

    it "returns all zeros when the cache is empty" do
      expect(described_class.new.entry_buckets).to all(eq(0))
    end

    it "counts entries created within the 24-hour window" do
      create_entry(key: "recent", value: "v", created_at: 1.hour.ago)
      expect(described_class.new.entry_buckets.sum).to eq(1)
    end

    it "excludes entries older than 24 hours" do
      create_entry(key: "old", value: "v", created_at: 25.hours.ago)
      expect(described_class.new.entry_buckets).to all(eq(0))
    end
  end

  describe "#byte_buckets" do
    it "returns 24 buckets" do
      expect(described_class.new.byte_buckets.size).to eq(24)
    end

    it "returns all zeros when the cache is empty" do
      expect(described_class.new.byte_buckets).to all(eq(0))
    end

    it "sums byte_size for entries in the window" do
      create_entry(key: "data", value: "hello", created_at: 1.hour.ago)
      expect(described_class.new.byte_buckets.sum).to be > 0
    end
  end

  describe "#entry_max" do
    it "returns 0 when the cache is empty" do
      expect(described_class.new.entry_max).to eq(0)
    end

    it "returns the highest bucket count" do
      2.times { |i| create_entry(key: "k#{i}", value: "v", created_at: 1.hour.ago) }
      create_entry(key: "k2", value: "v", created_at: 5.hours.ago)
      expect(described_class.new.entry_max).to eq(2)
    end
  end

  describe "#byte_max" do
    it "returns 0 when the cache is empty" do
      expect(described_class.new.byte_max).to eq(0)
    end

    it "returns the highest byte sum across buckets" do
      create_entry(key: "big", value: "x" * 100, created_at: 1.hour.ago)
      expect(described_class.new.byte_max).to be > 0
    end
  end
end
