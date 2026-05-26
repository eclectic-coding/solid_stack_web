require "rails_helper"

RSpec.describe SolidStackWeb::CacheStats do
  def create_entry(key: "k", value: "v")
    SolidCache::Entry.write(key, value)
  end

  describe "#to_h" do
    it "returns zeros and nil when the cache is empty" do
      stats = described_class.new.to_h
      expect(stats[:entries]).to eq(0)
      expect(stats[:byte_size]).to eq(0)
      expect(stats[:oldest_entry]).to be_nil
    end

    it "counts entries" do
      create_entry(key: "a", value: "x")
      create_entry(key: "b", value: "y")
      expect(described_class.new.to_h[:entries]).to eq(2)
    end

    it "sums byte_size across all entries" do
      create_entry(key: "small", value: "x")
      create_entry(key: "large", value: "x" * 100)
      total = SolidCache::Entry.sum(:byte_size)
      expect(described_class.new.to_h[:byte_size]).to eq(total)
    end

    it "returns the oldest entry timestamp" do
      travel_to 10.minutes.ago do
        create_entry(key: "old", value: "o")
      end
      create_entry(key: "new", value: "n")
      oldest = SolidCache::Entry.minimum(:created_at)
      expect(described_class.new.to_h[:oldest_entry]).to be_within(1.second).of(oldest)
    end
  end
end
