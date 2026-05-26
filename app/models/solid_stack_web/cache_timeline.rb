module SolidStackWeb
  class CacheTimeline
    HOURS = 24

    def entry_buckets
      @entry_buckets ||= build_buckets { |rows, from, to| rows.count { |t, _| t >= from && t < to } }
    end

    def byte_buckets
      @byte_buckets ||= build_buckets { |rows, from, to| rows.sum { |t, b| t >= from && t < to ? b : 0 } }
    end

    def entry_max
      entry_buckets.max || 0
    end

    def byte_max
      byte_buckets.max || 0
    end

    private

    def rows
      @rows ||= begin
        origin = Time.current - HOURS.hours
        ::SolidCache::Entry.where(created_at: origin..Time.current).pluck(:created_at, :byte_size)
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
