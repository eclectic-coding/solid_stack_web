module SolidStackWeb
  class CacheController < ApplicationController
    def index
      @total_entries   = ::SolidCache::Entry.count
      @total_byte_size = ::SolidCache::Entry.sum(:byte_size)
    end
  end
end
