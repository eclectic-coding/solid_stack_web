require "rails_helper"

RSpec.describe SolidStackWeb::CableTimeline do
  def broadcast(channel, payload = "msg", created_at: Time.current)
    SolidCable::Message.broadcast(channel, payload)
    SolidCable::Message.order(created_at: :desc).first.tap do |m|
      m.update_columns(created_at: created_at)
    end
  end

  describe "#message_buckets" do
    it "returns 24 buckets" do
      expect(described_class.new.message_buckets.size).to eq(24)
    end

    it "returns all zeros when there are no messages" do
      expect(described_class.new.message_buckets).to all(eq(0))
    end

    it "counts messages in the correct hour bucket" do
      broadcast("chat", "hi", created_at: 1.hour.ago)
      expect(described_class.new.message_buckets.sum).to eq(1)
    end

    it "excludes messages older than 24 hours" do
      broadcast("chat", "old", created_at: 25.hours.ago)
      expect(described_class.new.message_buckets).to all(eq(0))
    end

    it "places messages in separate buckets based on hour" do
      broadcast("chat", "early", created_at: 5.hours.ago)
      broadcast("chat", "recent", created_at: 1.hour.ago)
      buckets = described_class.new.message_buckets
      expect(buckets.count { |b| b > 0 }).to eq(2)
    end
  end

  describe "#message_max" do
    it "returns 0 when there are no messages" do
      expect(described_class.new.message_max).to eq(0)
    end

    it "returns the highest bucket count" do
      2.times { broadcast("chat", "m", created_at: 1.hour.ago) }
      broadcast("sports", "g", created_at: 5.hours.ago)
      expect(described_class.new.message_max).to eq(2)
    end
  end
end
