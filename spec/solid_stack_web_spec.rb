require "rails_helper"

RSpec.describe SolidStackWeb do
  describe ".configure" do
    it "yields self so callers can set attributes in a block" do
      SolidStackWeb.configure do |config|
        config.page_size = 50
      end

      expect(SolidStackWeb.page_size).to eq(50)
    ensure
      SolidStackWeb.page_size = 25
    end
  end

  describe ".mount_path" do
    it "returns the path at which the engine is mounted in the dummy app" do
      expect(SolidStackWeb.mount_path).to eq("/solid_stack")
    end

    it "returns a string with no trailing format suffix" do
      expect(SolidStackWeb.mount_path).not_to include("(")
    end
  end

  describe ".search_results_limit" do
    it "defaults to 25" do
      expect(SolidStackWeb.search_results_limit).to eq(25)
    end

    it "returns the configured value" do
      SolidStackWeb.search_results_limit = 50
      expect(SolidStackWeb.search_results_limit).to eq(50)
    ensure
      SolidStackWeb.search_results_limit = nil
    end
  end
end
