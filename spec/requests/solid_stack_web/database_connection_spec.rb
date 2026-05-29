require "rails_helper"

RSpec.describe "Database connection routing", type: :request do
  let(:engine_root) { "/solid_stack" }

  around do |example|
    original = SolidStackWeb.connects_to
    example.run
  ensure
    SolidStackWeb.instance_variable_set(:@connects_to, original)
  end

  context "when connects_to has :reading and :writing roles" do
    before { SolidStackWeb.connects_to = { reading: :reading, writing: :writing } }

    it "uses the reading role for GET requests" do
      allow(ActiveRecord::Base).to receive(:connected_to).and_yield
      get "#{engine_root}/jobs"
      expect(ActiveRecord::Base).to have_received(:connected_to).with(role: :reading)
    end

    it "uses the writing role for non-GET requests" do
      allow(ActiveRecord::Base).to receive(:connected_to).and_yield
      SolidQueue::Job.create!(class_name: "MyJob", queue_name: "default")
      post "#{engine_root}/queues/default/pause"
      expect(ActiveRecord::Base).to have_received(:connected_to).with(role: :writing)
    end
  end

  context "when connects_to has a single arbitrary config" do
    before { SolidStackWeb.connects_to = { role: :primary } }

    it "splats the config directly into connected_to" do
      allow(ActiveRecord::Base).to receive(:connected_to).and_yield
      get "#{engine_root}/jobs"
      expect(ActiveRecord::Base).to have_received(:connected_to).with(role: :primary)
    end
  end
end
