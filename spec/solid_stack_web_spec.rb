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

  describe ".deprecator" do
    it "returns an ActiveSupport::Deprecation instance scoped to SolidStackWeb" do
      expect(SolidStackWeb.deprecator).to be_a(ActiveSupport::Deprecation)
    end

    it "returns the same instance on repeated calls" do
      expect(SolidStackWeb.deprecator).to be(SolidStackWeb.deprecator)
    end
  end

  describe ".deprecated_config" do
    it "issues a deprecation warning and forwards the value to the new key" do
      SolidStackWeb.send(:deprecated_config, :legacy_limit, :search_results_limit)

      warned = false
      SolidStackWeb.deprecator.behavior = ->(msg, *) { warned = true if msg.include?("config.legacy_limit=") }

      SolidStackWeb.legacy_limit = 42
      expect(warned).to be(true)
      expect(SolidStackWeb.search_results_limit).to eq(42)
    ensure
      SolidStackWeb.search_results_limit = nil
      SolidStackWeb.deprecator.behavior = :stderr
      SolidStackWeb.singleton_class.remove_method(:legacy_limit=)
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
