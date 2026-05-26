module SolidStackWeb
  class Cache::FlushesController < ApplicationController
    def destroy
      ::SolidCache::Entry.delete_all
      redirect_to cache_entries_path, notice: "All cache entries flushed."
    end
  end
end
