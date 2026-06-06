module SolidStackWeb
  class Cache::FlushesController < ApplicationController
    def destroy
      ::SolidCache::Entry.delete_all
      redirect_to cache_entries_path, notice: t("solid_stack_web.flash.cache_flushed")
    end
  end
end
