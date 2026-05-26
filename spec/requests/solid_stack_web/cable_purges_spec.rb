require "rails_helper"

RSpec.describe "CablePurges", type: :request do
  let(:engine_root) { "/solid_stack" }

  def broadcast(channel, payload = "msg")
    SolidCable::Message.broadcast(channel, payload)
  end

  describe "DELETE /cable/purge" do
    it "deletes messages older than the specified number of days" do
      broadcast("chat", "old")
      SolidCable::Message.update_all(created_at: 10.days.ago)
      broadcast("chat", "new")

      delete "#{engine_root}/cable/purge", params: { older_than: 7 }

      remaining = SolidCable::Message.pluck(:payload)
      expect(remaining).to include("new")
      expect(remaining).not_to include("old")
    end

    it "redirects to the cable index" do
      delete "#{engine_root}/cable/purge", params: { older_than: 7 }
      expect(response).to redirect_to("#{engine_root}/cable")
    end

    it "treats a missing older_than as 1 day minimum" do
      broadcast("chat", "recent")
      SolidCable::Message.update_all(created_at: 2.days.ago)

      delete "#{engine_root}/cable/purge"

      expect(SolidCable::Message.count).to eq(0)
    end

    it "does not delete messages newer than the threshold" do
      broadcast("chat", "fresh")

      delete "#{engine_root}/cable/purge", params: { older_than: 7 }

      expect(SolidCable::Message.count).to eq(1)
    end
  end

  describe "DELETE /cable/channels/:channel_hash/purge" do
    it "deletes all messages for the channel" do
      SolidCable::Message.broadcast("sports", "goal")
      SolidCable::Message.broadcast("sports", "offside")
      hash = SolidCable::Message.where(channel: "sports").pick(:channel_hash)

      delete "#{engine_root}/cable/channels/#{hash}/purge"

      expect(SolidCable::Message.where(channel: "sports").count).to eq(0)
    end

    it "does not delete messages from other channels" do
      SolidCable::Message.broadcast("sports", "goal")
      SolidCable::Message.broadcast("chat", "hello")
      hash = SolidCable::Message.where(channel: "sports").pick(:channel_hash)

      delete "#{engine_root}/cable/channels/#{hash}/purge"

      expect(SolidCable::Message.where(channel: "chat").count).to eq(1)
    end

    it "redirects to the cable index" do
      SolidCable::Message.broadcast("sports", "goal")
      hash = SolidCable::Message.where(channel: "sports").pick(:channel_hash)

      delete "#{engine_root}/cable/channels/#{hash}/purge"

      expect(response).to redirect_to("#{engine_root}/cable")
    end
  end
end
