require "rails_helper"

RSpec.describe SolidStackWeb::QueueDepthSparkline do
  def create_job(queue_name: "default", created_at: Time.current, finished_at: nil)
    SolidQueue::Job.create!(class_name: "MyJob", queue_name:,
                            created_at:, finished_at:)
  end

  describe "#buckets" do
    it "returns 12 buckets" do
      expect(described_class.new("default").buckets.size).to eq(12)
    end

    it "returns all zeros when there are no jobs" do
      expect(described_class.new("default").buckets).to all(eq(0))
    end

    it "counts a currently ready job in every bucket after it was enqueued" do
      # 5.5h ago: sits between snapshot i=5 (6h ago) and i=6 (5h ago), first appears at i=6
      create_job(queue_name: "default", created_at: 5.5.hours.ago)
      buckets = described_class.new("default").buckets
      expect(buckets[6..11]).to all(be >= 1)
      expect(buckets[0..5]).to all(eq(0))
    end

    it "excludes a job that finished before the snapshot time" do
      # created 11.5h ago, finished 10.5h ago — present only at i=0 snapshot (11h ago)
      create_job(queue_name: "default", created_at: 11.5.hours.ago, finished_at: 10.5.hours.ago)
      buckets = described_class.new("default").buckets
      expect(buckets[0]).to eq(1)
      expect(buckets[1..11]).to all(eq(0))
    end

    it "excludes jobs from other queues" do
      create_job(queue_name: "other", created_at: 1.hour.ago)
      expect(described_class.new("default").buckets).to all(eq(0))
    end

    it "excludes jobs enqueued after the window" do
      create_job(queue_name: "default", created_at: 13.hours.ago, finished_at: 13.hours.ago)
      expect(described_class.new("default").buckets).to all(eq(0))
    end
  end

  describe "#max" do
    it "returns 0 when there are no jobs" do
      expect(described_class.new("default").max).to eq(0)
    end

    it "returns the highest bucket value" do
      create_job(queue_name: "default", created_at: 2.hours.ago)
      create_job(queue_name: "default", created_at: 2.hours.ago)
      create_job(queue_name: "default", created_at: 30.minutes.ago)
      expect(described_class.new("default").max).to eq(3)
    end
  end
end
