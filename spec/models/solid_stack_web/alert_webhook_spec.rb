require "rails_helper"

RSpec.describe SolidStackWeb::AlertWebhook do
  let(:webhook_url) { "https://hooks.example.com/alert" }
  let(:queue_stats) { { failed: 0, ready: 0 } }

  after do
    SolidStackWeb.alert_webhook_url       = nil
    SolidStackWeb.alert_failure_threshold = nil
    SolidStackWeb.alert_queue_thresholds  = nil
    SolidStackWeb.alert_webhook_cooldown  = nil
    Rails.cache.clear
  end

  describe ".check" do
    context "when no webhook URL is configured" do
      it "does not make any HTTP requests" do
        SolidStackWeb.alert_failure_threshold = 1
        stub = stub_request(:post, webhook_url)
        described_class.check(queue_stats.merge(failed: 5))
        expect(stub).not_to have_been_requested
      end
    end

    context "when webhook URL is configured" do
      before { SolidStackWeb.alert_webhook_url = webhook_url }

      it "does not POST when no thresholds are configured" do
        stub = stub_request(:post, webhook_url)
        described_class.check(queue_stats)
        expect(stub).not_to have_been_requested
      end

      it "does not POST when failed count is below threshold" do
        SolidStackWeb.alert_failure_threshold = 10
        stub = stub_request(:post, webhook_url)
        described_class.check(queue_stats.merge(failed: 5))
        expect(stub).not_to have_been_requested
      end

      it "POSTs when failed count meets the threshold" do
        SolidStackWeb.alert_failure_threshold = 5
        stub = stub_request(:post, webhook_url).to_return(status: 200)
        described_class.check(queue_stats.merge(failed: 5))
        expect(stub).to have_been_requested
      end

      it "includes alert details in the payload" do
        SolidStackWeb.alert_failure_threshold = 3
        stub = stub_request(:post, webhook_url)
          .with { |req| JSON.parse(req.body)["alerts"].first["type"] == "failed_jobs" }
          .to_return(status: 200)
        described_class.check(queue_stats.merge(failed: 4))
        expect(stub).to have_been_requested
      end

      it "POSTs when a queue depth meets its threshold" do
        SolidStackWeb.alert_queue_thresholds = { "critical" => 2 }
        2.times { SolidQueue::Job.create!(class_name: "A", queue_name: "critical") }
        stub = stub_request(:post, webhook_url).to_return(status: 200)
        described_class.check(queue_stats)
        expect(stub).to have_been_requested
      end

      it "does not POST again while on cooldown" do
        SolidStackWeb.alert_failure_threshold = 1
        SolidStackWeb.alert_webhook_cooldown  = 3600
        stub = stub_request(:post, webhook_url).to_return(status: 200)
        described_class.check(queue_stats.merge(failed: 5))
        described_class.check(queue_stats.merge(failed: 5))
        expect(stub).to have_been_requested.once
      end

      it "does not raise when the webhook request fails" do
        SolidStackWeb.alert_failure_threshold = 1
        stub_request(:post, webhook_url).to_raise(Net::OpenTimeout)
        expect { described_class.check(queue_stats.merge(failed: 5)) }.not_to raise_error
      end
    end
  end
end
