require "rails_helper"

RSpec.describe "CableMessages", type: :request do
  let(:engine_root) { "/solid_stack" }

  def broadcast(channel, payload = "test payload")
    SolidCable::Message.broadcast(channel, payload)
    SolidCable::Message.where(channel: channel).order(created_at: :desc).first
  end

  def channel_hash_for(channel)
    SolidCable::Message.where(channel: channel).pick(:channel_hash)
  end

  describe "GET /cable/channels/:channel_hash" do
    it "returns 200" do
      msg = broadcast("sports:scores", "goal!")
      get "#{engine_root}/cable/channels/#{msg.channel_hash}"
      expect(response).to have_http_status(:ok)
    end

    it "shows messages belonging to the channel" do
      broadcast("chat", "hello")
      broadcast("chat", "world")
      hash = channel_hash_for("chat")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("hello")
      expect(response.body).to include("world")
    end

    it "does not show messages from other channels" do
      broadcast("chat", "mine")
      broadcast("other", "not mine")
      hash = channel_hash_for("chat")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("mine")
      expect(response.body).not_to include("not mine")
    end

    it "orders messages newest first" do
      broadcast("feed", "first message")
      travel 1.second do
        broadcast("feed", "second message")
      end
      hash = channel_hash_for("feed")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body.index("second message")).to be < response.body.index("first message")
    end

    it "shows the channel name as the page title" do
      broadcast("notifications:user:42", "ping")
      hash = channel_hash_for("notifications:user:42")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("notifications:user:42")
    end

    it "renders payloads containing non-ASCII characters" do
      # solid_cable 4.0+ stores payloads in a binary (bytea) column, so the
      # view receives an ASCII-8BIT (BINARY) string. Appending a BINARY value
      # with non-ASCII bytes to the UTF-8 output buffer (which already holds
      # non-ASCII text from the layout) used to raise
      # Encoding::CompatibilityError. The "→" in a Turbo Stream payload is a
      # common real-world trigger.
      payload = %(<turbo-stream action="update" method="patch" target="display-live">update → live</turbo-stream>)
      broadcast("display:live", payload)
      hash = channel_hash_for("display:live")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("→")
    end

    it "renders channel names containing non-ASCII characters" do
      channel = "chat:→:thread"
      broadcast(channel, "hello")
      hash = channel_hash_for(channel)

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("→")
    end

    it "truncates long payloads in the preview" do
      broadcast("log", "x" * 200)
      hash = channel_hash_for("log")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("#{"x" * 117}...")
    end

    it "includes a back link to the channel browser" do
      broadcast("chat", "msg")
      hash = channel_hash_for("chat")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("← Channels")
    end

    it "shows empty state for an unknown channel_hash" do
      get "#{engine_root}/cable/channels/nonexistent000"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No messages for this channel")
    end

    it "filters messages by payload substring" do
      broadcast("events", "user_signed_in")
      broadcast("events", "order_placed")
      hash = channel_hash_for("events")

      get "#{engine_root}/cable/channels/#{hash}", params: { q: "signed" }

      expect(response.body).to include("user_signed_in")
      expect(response.body).not_to include("order_placed")
    end

    it "shows contextual empty state when payload search yields no results" do
      broadcast("events", "something")
      hash = channel_hash_for("events")

      get "#{engine_root}/cable/channels/#{hash}", params: { q: "nope" }

      expect(response.body).to include("No messages matching")
    end

    it "shows a clear link when a payload search is active" do
      broadcast("events", "ping")
      hash = channel_hash_for("events")

      get "#{engine_root}/cable/channels/#{hash}", params: { q: "ping" }

      expect(response.body).to include("Clear")
    end
  end

  describe "pagination" do
    it "shows pagination controls when messages exceed one page" do
      26.times { |i| broadcast("logs", "msg#{i}") }
      hash = channel_hash_for("logs")

      get "#{engine_root}/cable/channels/#{hash}"

      expect(response.body).to include("page=2")
    end

    it "returns 200 for page 2" do
      26.times { |i| broadcast("logs", "msg#{i}") }
      hash = channel_hash_for("logs")

      get "#{engine_root}/cable/channels/#{hash}", params: { page: 2 }

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for an out-of-range page" do
      broadcast("logs", "single")
      hash = channel_hash_for("logs")

      get "#{engine_root}/cable/channels/#{hash}", params: { page: 999 }

      expect(response).to have_http_status(:ok)
    end
  end
end
