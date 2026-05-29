require "rails_helper"

RSpec.describe SolidStackWeb::ApplicationHelper, type: :helper do
  describe "#format_cache_value" do
    it "returns JSON label and pretty-printed content for valid JSON input" do
      result = helper.format_cache_value('{"key":"value"}')
      expect(result[:label]).to eq("JSON")
      expect(result[:content]).to include('"key": "value"')
    end

    it "returns Text label and raw content for non-JSON input" do
      result = helper.format_cache_value("plain string")
      expect(result[:label]).to eq("Text")
      expect(result[:content]).to eq("plain string")
    end

    it "replaces invalid bytes and returns Text label" do
      result = helper.format_cache_value("\xFF\xFE")
      expect(result[:label]).to eq("Text")
      expect(result[:content]).to include("?")
    end
  end

  describe "#format_duration" do
    it "returns seconds for values under 60" do
      expect(helper.format_duration(45)).to eq("45s")
    end

    it "returns minutes and seconds for values between 60 and 3599" do
      expect(helper.format_duration(90)).to eq("1m 30s")
    end

    it "returns zero seconds in the minutes branch at an exact minute boundary" do
      expect(helper.format_duration(120)).to eq("2m 0s")
    end

    it "returns hours and minutes for values 3600 and above" do
      expect(helper.format_duration(3661)).to eq("1h 1m")
    end

    it "returns hours and zero minutes at an exact hour boundary" do
      expect(helper.format_duration(7200)).to eq("2h 0m")
    end
  end

  describe "#audit_action_badge_class" do
    it "returns failed badge class for discard actions" do
      expect(helper.audit_action_badge_class("discard")).to eq("sqw-badge--failed")
    end

    it "returns scheduled badge class for retry actions" do
      expect(helper.audit_action_badge_class("retry")).to eq("sqw-badge--scheduled")
    end

    it "returns blocked badge class for queue_paused" do
      expect(helper.audit_action_badge_class("queue_paused")).to eq("sqw-badge--blocked")
    end

    it "returns ready badge class for queue_resumed" do
      expect(helper.audit_action_badge_class("queue_resumed")).to eq("sqw-badge--ready")
    end
  end
end
