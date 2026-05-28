require "rails_helper"

RSpec.describe SolidStackWeb::AlertWebhook do
  let(:webhook_url) { "https://hooks.example.com/alert" }
  let(:queue_stats) { { failed: 0, ready: 0 } }

  after do
    SolidStackWeb.alert_webhook_url              = nil
    SolidStackWeb.alert_failure_threshold        = nil
    SolidStackWeb.alert_queue_thresholds         = nil
    SolidStackWeb.alert_slow_job_count_threshold = nil
    SolidStackWeb.alert_webhook_cooldown         = nil
    SolidStackWeb.slow_job_threshold             = nil
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

      context "slow job threshold" do
        let(:worker) do
          SolidQueue::Process.create!(kind: "Worker", name: "worker-spec", pid: 99_999,
                                      hostname: "test", last_heartbeat_at: Time.current)
        end

        def claimed_job(created_at:)
          SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
          job = SolidQueue::Job.create!(class_name: "SlowJob", queue_name: "default")
          SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
          SolidQueue::ClaimedExecution.create!(job: job, process_id: worker.id, created_at: created_at)
        end

        before do
          SolidStackWeb.slow_job_threshold             = 300
          SolidStackWeb.alert_slow_job_count_threshold = 2
        end

        it "does not POST when slow claimed job count is below the count threshold" do
          claimed_job(created_at: 10.minutes.ago)
          stub = stub_request(:post, webhook_url).to_return(status: 200)
          described_class.check(queue_stats)
          expect(stub).not_to have_been_requested
        end

        it "POSTs when slow claimed job count meets the count threshold" do
          2.times { claimed_job(created_at: 10.minutes.ago) }
          stub = stub_request(:post, webhook_url).to_return(status: 200)
          described_class.check(queue_stats)
          expect(stub).to have_been_requested
        end

        it "does not POST for claimed jobs within the slow_job_threshold window" do
          claimed_job(created_at: 1.minute.ago)
          claimed_job(created_at: 1.minute.ago)
          stub = stub_request(:post, webhook_url).to_return(status: 200)
          described_class.check(queue_stats)
          expect(stub).not_to have_been_requested
        end

        it "includes slow_jobs type in the payload" do
          2.times { claimed_job(created_at: 10.minutes.ago) }
          stub = stub_request(:post, webhook_url)
            .with { |req| JSON.parse(req.body)["alerts"].any? { |a| a["type"] == "slow_jobs" } }
            .to_return(status: 200)
          described_class.check(queue_stats)
          expect(stub).to have_been_requested
        end

        it "does not POST when slow_job_threshold is not set" do
          SolidStackWeb.slow_job_threshold = nil
          claimed_job(created_at: 10.minutes.ago)
          claimed_job(created_at: 10.minutes.ago)
          stub = stub_request(:post, webhook_url).to_return(status: 200)
          described_class.check(queue_stats)
          expect(stub).not_to have_been_requested
        end
      end
    end
  end
end
