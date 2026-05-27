module SolidStackWeb
  class CacheSizeStats
    BUCKETS = [
      { label: "< 1 KB",       min: 0,       max: 1_024 },
      { label: "1 – 10 KB",    min: 1_024,   max: 10_240 },
      { label: "10 – 100 KB",  min: 10_240,  max: 102_400 },
      { label: "100 KB – 1 MB", min: 102_400, max: 1_048_576 },
      { label: "> 1 MB",       min: 1_048_576, max: nil }
    ].freeze

    TOP_N = 10

    def top_entries
      @top_entries ||= ::SolidCache::Entry
                         .select(:id, :key, :byte_size)
                         .order(byte_size: :desc)
                         .limit(TOP_N)
    end

    def buckets
      @buckets ||= begin
        row = ::SolidCache::Entry.pluck(
          Arel.sql("COALESCE(SUM(CASE WHEN byte_size < 1024 THEN 1 ELSE 0 END), 0)"),
          Arel.sql("COALESCE(SUM(CASE WHEN byte_size >= 1024 AND byte_size < 10240 THEN 1 ELSE 0 END), 0)"),
          Arel.sql("COALESCE(SUM(CASE WHEN byte_size >= 10240 AND byte_size < 102400 THEN 1 ELSE 0 END), 0)"),
          Arel.sql("COALESCE(SUM(CASE WHEN byte_size >= 102400 AND byte_size < 1048576 THEN 1 ELSE 0 END), 0)"),
          Arel.sql("COALESCE(SUM(CASE WHEN byte_size >= 1048576 THEN 1 ELSE 0 END), 0)")
        ).first || Array.new(5, 0)
        BUCKETS.zip(row).map { |b, count| { label: b[:label], count: count.to_i } }
      end
    end

    def total
      @total ||= buckets.sum { |b| b[:count] }
    end
  end
end
