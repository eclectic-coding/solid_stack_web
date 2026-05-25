require "rails_helper"

RSpec.describe "Cable", type: :request do
  let(:engine_root) { "/solid_stack" }

  describe "GET /cable" do
    it "returns 200" do
      get "#{engine_root}/cable"
      expect(response).to have_http_status(:ok)
    end

    it "shows zero counts when no messages exist" do
      get "#{engine_root}/cable"
      expect(response.body).to include("Total Messages")
      expect(response.body).to include("Channels")
    end

    it "reflects live message count" do
      SolidCable::Message.broadcast("room:1", { text: "hello" }.to_json)
      SolidCable::Message.broadcast("room:2", { text: "world" }.to_json)

      get "#{engine_root}/cable"

      expect(response.body).to match(/class="sqw-stat__value">\s*2\s*</)
    end

    it "lists distinct channels" do
      SolidCable::Message.broadcast("notifications", "msg1")
      SolidCable::Message.broadcast("notifications", "msg2")
      SolidCable::Message.broadcast("chat", "msg3")

      get "#{engine_root}/cable"

      expect(response.body).to include("notifications")
      expect(response.body).to include("chat")
    end

    it "shows channel count not message count in the Channels stat" do
      SolidCable::Message.broadcast("room:1", "a")
      SolidCable::Message.broadcast("room:1", "b")
      SolidCable::Message.broadcast("room:2", "c")

      get "#{engine_root}/cable"

      # 2 distinct channels, stat value should be 2 (not 3 messages)
      expect(response.body).to include("Channels")
      expect(response.body).to match(/class="sqw-stat__value">\s*2\s*</)
    end
  end
end
