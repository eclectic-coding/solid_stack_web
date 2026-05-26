require "rails_helper"

RSpec.describe SolidStackWeb::CableStats do
  def broadcast(channel, payload = "msg")
    SolidCable::Message.broadcast(channel, payload)
  end

  describe "#to_h" do
    it "returns zeros and nil when there are no messages" do
      stats = described_class.new.to_h
      expect(stats[:messages]).to eq(0)
      expect(stats[:channels]).to eq(0)
      expect(stats[:messages_per_hour]).to eq(0)
      expect(stats[:oldest_message]).to be_nil
      expect(stats[:top_channels]).to be_empty
    end

    it "counts total messages" do
      broadcast("chat", "hello")
      broadcast("chat", "world")
      expect(described_class.new.to_h[:messages]).to eq(2)
    end

    it "counts distinct channels" do
      broadcast("chat", "hi")
      broadcast("sports", "goal")
      broadcast("sports", "offside")
      expect(described_class.new.to_h[:channels]).to eq(2)
    end

    it "counts messages sent in the last hour" do
      broadcast("chat", "recent")
      old = SolidCable::Message.last
      old.update_columns(created_at: 2.hours.ago)
      broadcast("chat", "new")
      expect(described_class.new.to_h[:messages_per_hour]).to eq(1)
    end

    it "returns the oldest message timestamp" do
      travel_to 10.minutes.ago do
        broadcast("chat", "first")
      end
      broadcast("chat", "second")
      oldest = SolidCable::Message.minimum(:created_at)
      expect(described_class.new.to_h[:oldest_message]).to be_within(1.second).of(oldest)
    end

    it "returns the top 3 channels by message volume" do
      3.times { broadcast("alpha", "m") }
      2.times { broadcast("beta", "m") }
      1.times { broadcast("gamma", "m") }
      broadcast("delta", "m")

      top = described_class.new.to_h[:top_channels]
      expect(top.keys.first).to eq("alpha")
      expect(top.size).to be <= 3
    end
  end
end
