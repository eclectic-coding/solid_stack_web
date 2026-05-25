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
end