module SolidStackWeb
  class CacheController < ApplicationController
    def index
      @total_entries   = ::SolidCache::Entry.count
      @total_byte_size = ::SolidCache::Entry.sum(:byte_size)
      @size_stats      = CacheSizeStats.new
    end
  end
end
