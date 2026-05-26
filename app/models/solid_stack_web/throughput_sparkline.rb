module SolidStackWeb
  class ThroughputSparkline
    HOURS = 12

    def buckets
      @buckets ||= begin
        now    = Time.current
        origin = now - HOURS.hours
        times  = ::SolidQueue::Job.where(finished_at: origin..now).pluck(:finished_at)

        HOURS.times.map do |i|
          from = origin + i.hours
          to   = origin + (i + 1).hours
          times.count { |t| t >= from && t < to }
        end
      end
    end

    def max
      buckets.max || 0
    end
  end
end
