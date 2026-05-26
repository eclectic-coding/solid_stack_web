module SolidStackWeb
  class CableTimeline
    HOURS = 24

    def message_buckets
      @message_buckets ||= build_buckets { |rows, from, to| rows.count { |t| t >= from && t < to } }
    end

    def message_max
      message_buckets.max || 0
    end

    private

    def rows
      @rows ||= begin
        origin = Time.current - HOURS.hours
        ::SolidCable::Message.where(created_at: origin..Time.current).pluck(:created_at)
      end
    end

    def build_buckets(&block)
      now    = Time.current
      origin = now - HOURS.hours
      HOURS.times.map do |i|
        from = origin + i.hours
        to   = origin + (i + 1).hours
        block.call(rows, from, to)
      end
    end
  end
end
