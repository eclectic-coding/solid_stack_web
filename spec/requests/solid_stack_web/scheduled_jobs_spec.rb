require "rails_helper"

RSpec.describe "ScheduledJobs", type: :request do
  let(:engine_root) { "/solid_stack" }

  def create_scheduled(class_name: "ScheduledJob", queue_name: "default", scheduled_at: 2.hours.from_now)
    SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
    job = SolidQueue::Job.create!(
      class_name:, queue_name:, priority: 0, scheduled_at:,
      arguments: { "executions" => 0, "exception_executions" => {} }
    )
    SolidQueue::ScheduledExecution.create!(
      job: job, queue_name:, priority: 0, scheduled_at:
    )
    SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
    job
  end

  describe "POST /scheduled_jobs/run_all_now" do
    it "back-dates all scheduled executions and redirects with notice" do
      create_scheduled

      post "#{engine_root}/scheduled_jobs/run_all_now"

      expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
      follow_redirect!
      expect(response.body).to include("scheduled to run immediately")
    end

    it "sets scheduled_at to the past for each execution" do
      job = create_scheduled

      post "#{engine_root}/scheduled_jobs/run_all_now"

      expect(job.scheduled_execution.reload.scheduled_at).to be <= Time.current
    end

    it "also updates the underlying job's scheduled_at" do
      job = create_scheduled

      post "#{engine_root}/scheduled_jobs/run_all_now"

      expect(job.reload.scheduled_at).to be <= Time.current
    end

    it "includes the count in the notice" do
      create_scheduled

      post "#{engine_root}/scheduled_jobs/run_all_now"
      follow_redirect!

      expect(response.body).to include("1 job scheduled to run immediately")
    end

    it "pluralises correctly for multiple jobs" do
      create_scheduled(class_name: "JobA")
      create_scheduled(class_name: "JobB")

      post "#{engine_root}/scheduled_jobs/run_all_now"
      follow_redirect!

      expect(response.body).to include("2 jobs scheduled to run immediately")
    end

    it "preserves period in the redirect" do
      post "#{engine_root}/scheduled_jobs/run_all_now", params: { period: "24h" }

      expect(response).to redirect_to("#{engine_root}/jobs?period=24h&status=scheduled")
    end

    it "redirects with alert when an error occurs" do
      allow(SolidQueue::ScheduledExecution).to receive(:joins).and_raise(RuntimeError, "db error")

      post "#{engine_root}/scheduled_jobs/run_all_now"

      expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
      expect(flash[:alert]).to include("Could not run jobs")
    end
  end

  describe "PATCH /scheduled_jobs/:id" do
    context "with offset=now" do
      it "sets scheduled_at to the past and redirects" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "now" }

        expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
        expect(execution.reload.scheduled_at).to be <= Time.current
      end

      it "also updates the job's scheduled_at" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "now" }

        expect(job.reload.scheduled_at).to be <= Time.current
      end

      it "removes the row via turbo stream" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}",
              params: { offset: "now" },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("execution_#{execution.id}")
        expect(response.body).to include("remove")
      end
    end

    context "with offset=1h" do
      it "postpones scheduled_at by 1 hour and redirects" do
        job = create_scheduled
        execution = job.scheduled_execution
        original = execution.scheduled_at

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "1h" }

        expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
        expect(execution.reload.scheduled_at).to be_within(5.seconds).of(original + 1.hour)
      end

      it "updates the cell via turbo stream" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}",
              params: { offset: "1h" },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("scheduled_at_#{execution.id}")
        expect(response.body).to include("replace")
      end
    end

    context "with offset=24h" do
      it "postpones scheduled_at by 24 hours" do
        job = create_scheduled
        execution = job.scheduled_execution
        original = execution.scheduled_at

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "24h" }

        expect(execution.reload.scheduled_at).to be_within(5.seconds).of(original + 24.hours)
      end
    end

    context "with offset=7d" do
      it "postpones scheduled_at by 7 days" do
        job = create_scheduled
        execution = job.scheduled_execution
        original = execution.scheduled_at

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "7d" }

        expect(execution.reload.scheduled_at).to be_within(5.seconds).of(original + 7.days)
      end
    end

    context "with an invalid offset" do
      it "redirects with an alert" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "bogus" }

        expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
        follow_redirect!
        expect(response.body).to include("Invalid offset")
      end

      it "does not modify scheduled_at" do
        job = create_scheduled
        execution = job.scheduled_execution
        original = execution.scheduled_at

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "bogus" }

        expect(execution.reload.scheduled_at).to be_within(1.second).of(original)
      end
    end

    context "with a missing execution" do
      it "redirects with an alert" do
        patch "#{engine_root}/scheduled_jobs/0", params: { offset: "now" }

        expect(response).to redirect_to("#{engine_root}/jobs?status=scheduled")
        follow_redirect!
        expect(response.body).to include("Could not reschedule job")
      end
    end

    context "when period param is present" do
      it "preserves period in the redirect" do
        job = create_scheduled
        execution = job.scheduled_execution

        patch "#{engine_root}/scheduled_jobs/#{execution.id}", params: { offset: "now", period: "24h" }

        expect(response).to redirect_to("#{engine_root}/jobs?period=24h&status=scheduled")
      end
    end
  end
end
