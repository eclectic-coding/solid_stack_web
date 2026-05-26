module SolidStackWeb
  class QueueStats
    def to_h
      finished_24h = finished_since(24.hours.ago)
      stats = {
        ready:             ::SolidQueue::ReadyExecution.count,
        scheduled:         ::SolidQueue::ScheduledExecution.count,
        claimed:           ::SolidQueue::ClaimedExecution.count,
        blocked:           ::SolidQueue::BlockedExecution.count,
        failed:            ::SolidQueue::FailedExecution.count,
        done_1h:           finished_since(1.hour.ago).count,
        done_24h:          finished_24h.count,
        processes_healthy: ::SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago).count,
        processes_stale:   ::SolidQueue::Process.where("last_heartbeat_at <= ? OR last_heartbeat_at IS NULL", 5.minutes.ago).count
      }
      add_slow_jobs(stats, finished_24h)
      stats
    end

    private

    def finished_since(time)
      ::SolidQueue::Job.where.not(finished_at: nil).where("finished_at >= ?", time)
    end

    def add_slow_jobs(stats, finished_24h)
      threshold = SolidStackWeb.slow_job_threshold
      return unless threshold

      stats[:slow_jobs] = finished_24h.select(:created_at, :finished_at)
                                      .count { |j| (j.finished_at - j.created_at) > threshold }
    end
  end
end
