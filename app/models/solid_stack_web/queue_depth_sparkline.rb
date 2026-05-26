module SolidStackWeb
  class QueueDepthSparkline
    HOURS = 12

    def initialize(queue_name)
      @queue_name = queue_name
    end

    def buckets
      @buckets ||= begin
        now    = Time.current
        origin = now - HOURS.hours

        jobs = ::SolidQueue::Job
                 .where(queue_name: @queue_name)
                 .where("created_at <= ? AND (finished_at IS NULL OR finished_at >= ?)", now, origin)
                 .pluck(:created_at, :finished_at)

        HOURS.times.map do |i|
          snapshot = origin + (i + 1).hours
          jobs.count { |created_at, finished_at| created_at <= snapshot && (finished_at.nil? || finished_at > snapshot) }
        end
      end
    end

    def max
      buckets.max || 0
    end
  end
end
