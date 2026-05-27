require "rails_helper"

RSpec.describe SolidStackWeb::FailedJobSparkline do
  def create_failed(created_at:)
    SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
    job = SolidQueue::Job.create!(class_name: "FailingJob", queue_name: "default",
                                  priority: 0, arguments: {})
    SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class: "RuntimeError", message: "boom", backtrace: [] },
      created_at: created_at
    )
  ensure
    SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
  end

  describe "#buckets" do
    it "returns 12 buckets" do
      expect(described_class.new.buckets.size).to eq(12)
    end

    it "returns all zeros when there are no failed executions" do
      expect(described_class.new.buckets).to all(eq(0))
    end

    it "counts a failure within the window in the correct bucket" do
      create_failed(created_at: 2.hours.ago)
      buckets = described_class.new.buckets
      expect(buckets[9]).to eq(1)
      expect(buckets.sum).to eq(1)
    end

    it "excludes failures outside the 12-hour window" do
      create_failed(created_at: 13.hours.ago)
      expect(described_class.new.buckets).to all(eq(0))
    end
  end

  describe "#max" do
    it "returns 0 when there are no failures" do
      expect(described_class.new.max).to eq(0)
    end

    it "returns the highest bucket count" do
      3.times { create_failed(created_at: 1.hour.ago) }
      create_failed(created_at: 5.hours.ago)
      expect(described_class.new.max).to eq(3)
    end
  end
end
