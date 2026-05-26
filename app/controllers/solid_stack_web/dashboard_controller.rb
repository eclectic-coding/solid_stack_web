module SolidStackWeb
  class DashboardController < ApplicationController
    def index
      finished_1h  = ::SolidQueue::Job.where.not(finished_at: nil).where("finished_at >= ?", 1.hour.ago)
      finished_24h = ::SolidQueue::Job.where.not(finished_at: nil).where("finished_at >= ?", 24.hours.ago)

      @queue_stats = {
        ready:              ::SolidQueue::ReadyExecution.count,
        scheduled:          ::SolidQueue::ScheduledExecution.count,
        claimed:            ::SolidQueue::ClaimedExecution.count,
        blocked:            ::SolidQueue::BlockedExecution.count,
        failed:             ::SolidQueue::FailedExecution.count,
        done_1h:            finished_1h.count,
        done_24h:           finished_24h.count,
        processes_healthy:  ::SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago).count,
        processes_stale:    ::SolidQueue::Process.where("last_heartbeat_at <= ? OR last_heartbeat_at IS NULL", 5.minutes.ago).count
      }

      if (threshold = SolidStackWeb.slow_job_threshold)
        @queue_stats[:slow_jobs] = finished_24h.select(:created_at, :finished_at)
                                               .count { |j| (j.finished_at - j.created_at) > threshold }
      end
      @cache_stats = {
        entries:   ::SolidCache::Entry.count,
        byte_size: ::SolidCache::Entry.sum(:byte_size)
      }
      @cable_stats = {
        messages: ::SolidCable::Message.count,
        channels: ::SolidCable::Message.distinct.count(:channel)
      }
    end
  end
end
