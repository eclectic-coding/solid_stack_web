require "rails_helper"

RSpec.describe SolidStackWeb::ApplicationHelper, type: :helper do
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
end