require "rails_helper"

RSpec.describe SolidStackWeb::ThroughputSparkline do
  describe "#buckets" do
    it "returns 12 buckets" do
      expect(described_class.new.buckets.size).to eq(12)
    end

    it "returns all zeros when no jobs have finished" do
      expect(described_class.new.buckets).to all(eq(0))
    end

    it "counts a job finished within the window in the correct bucket" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default",
                              finished_at: 2.hours.ago)
      buckets = described_class.new.buckets
      expect(buckets[9]).to eq(1)
      expect(buckets.sum).to eq(1)
    end

    it "excludes jobs finished outside the 12-hour window" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default",
                              finished_at: 13.hours.ago)
      expect(described_class.new.buckets).to all(eq(0))
    end

    it "excludes jobs with no finished_at" do
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")
      expect(described_class.new.buckets).to all(eq(0))
    end
  end

  describe "#max" do
    it "returns 0 when there are no finished jobs" do
      expect(described_class.new.max).to eq(0)
    end

    it "returns the highest bucket count" do
      3.times { SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default", finished_at: 1.hour.ago) }
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default", finished_at: 5.hours.ago)
      expect(described_class.new.max).to eq(3)
    end
  end
end
