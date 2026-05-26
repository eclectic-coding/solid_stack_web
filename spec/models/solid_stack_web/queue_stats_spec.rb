require "rails_helper"

RSpec.describe SolidStackWeb::QueueStats do
  def create_ready(queue_name: "default")
    SolidQueue::Job.create!(class_name: "MyJob", queue_name:, priority: 0)
  end

  def create_failed
    SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
    job = SolidQueue::Job.create!(class_name: "FailingJob", queue_name: "default", priority: 0)
    SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
    )
    SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
  end

  def create_process(heartbeat_at: Time.current)
    SolidQueue::Process.create!(
      kind: "Worker", name: "worker-#{SecureRandom.hex(4)}", pid: rand(99_999),
      hostname: "test", last_heartbeat_at: heartbeat_at
    )
  end

  def create_finished(finished_at: Time.current, duration: 10)
    SolidQueue::Job.create!(
      class_name: "FinishedJob", queue_name: "default", priority: 0,
      created_at: finished_at - duration.seconds,
      finished_at: finished_at
    )
  end

  after { SolidStackWeb.slow_job_threshold = nil }

  describe "#to_h" do
    it "returns zero counts when the queue is empty" do
      stats = described_class.new.to_h
      expect(stats[:ready]).to eq(0)
      expect(stats[:scheduled]).to eq(0)
      expect(stats[:claimed]).to eq(0)
      expect(stats[:blocked]).to eq(0)
      expect(stats[:failed]).to eq(0)
    end

    it "counts ready executions" do
      2.times { create_ready }
      expect(described_class.new.to_h[:ready]).to eq(2)
    end

    it "counts failed executions" do
      create_failed
      expect(described_class.new.to_h[:failed]).to eq(1)
    end

    it "counts jobs finished in the last hour" do
      create_finished(finished_at: 30.minutes.ago)
      create_finished(finished_at: 2.hours.ago)
      expect(described_class.new.to_h[:done_1h]).to eq(1)
    end

    it "counts jobs finished in the last 24 hours" do
      create_finished(finished_at: 1.hour.ago)
      create_finished(finished_at: 23.hours.ago)
      create_finished(finished_at: 25.hours.ago)
      expect(described_class.new.to_h[:done_24h]).to eq(2)
    end

    it "counts healthy processes (heartbeat within last 5 minutes)" do
      create_process(heartbeat_at: 2.minutes.ago)
      create_process(heartbeat_at: 10.minutes.ago)
      expect(described_class.new.to_h[:processes_healthy]).to eq(1)
    end

    it "counts stale processes (heartbeat older than 5 minutes)" do
      create_process(heartbeat_at: 2.minutes.ago)
      create_process(heartbeat_at: 10.minutes.ago)
      expect(described_class.new.to_h[:processes_stale]).to eq(1)
    end

    it "omits slow_jobs key when no threshold is configured" do
      expect(described_class.new.to_h).not_to have_key(:slow_jobs)
    end

    it "counts slow jobs when threshold is configured" do
      SolidStackWeb.slow_job_threshold = 30
      create_finished(duration: 60)
      create_finished(duration: 10)
      expect(described_class.new.to_h[:slow_jobs]).to eq(1)
    end
  end
end
