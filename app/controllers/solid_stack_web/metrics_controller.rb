module SolidStackWeb
  class MetricsController < ApplicationController
    def index
      queue_stats = QueueStats.new.to_h
      AlertWebhook.check(queue_stats)

      render json: {
        queue:        queue_stats,
        cache:        CacheStats.new.to_h,
        cable:        CableStats.new.to_h,
        generated_at: Time.current.iso8601
      }
    end
  end
end
