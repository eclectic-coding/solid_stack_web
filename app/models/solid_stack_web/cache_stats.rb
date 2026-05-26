module SolidStackWeb
  class CacheStats
    def to_h
      {
        entries:      ::SolidCache::Entry.count,
        byte_size:    ::SolidCache::Entry.sum(:byte_size),
        oldest_entry: ::SolidCache::Entry.minimum(:created_at)
      }
    end
  end
end
