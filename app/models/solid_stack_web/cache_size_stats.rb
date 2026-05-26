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
      @buckets ||= BUCKETS.map do |b|
        scope = ::SolidCache::Entry.all
        scope = scope.where("byte_size >= ?", b[:min]) if b[:min] > 0
        scope = scope.where("byte_size < ?",  b[:max]) if b[:max]
        { label: b[:label], count: scope.count }
      end
    end

    def total
      @total ||= ::SolidCache::Entry.count
    end
  end
end
