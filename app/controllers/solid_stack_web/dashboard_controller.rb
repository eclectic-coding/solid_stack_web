module SolidStackWeb
  class DashboardController < ApplicationController
    def index
      @queue_stats = QueueStats.new.to_h
      @cache_stats = CacheStats.new.to_h
      @cable_stats = CableStats.new.to_h
      @throughput  = ThroughputSparkline.new
      @failures    = FailedJobSparkline.new
      AlertWebhook.check(@queue_stats)
    end
  end
end
