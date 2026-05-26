module SolidStackWeb
  class DashboardController < ApplicationController
    def index
      @queue_stats = QueueStats.new.to_h
      @cache_stats = CacheStats.new.to_h
      @cable_stats = CableStats.new.to_h
    end
  end
end
