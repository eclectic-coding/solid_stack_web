module SolidStackWeb
  class MetricsController < ApplicationController
    def index
      render json: {
        queue:        QueueStats.new.to_h,
        cache:        CacheStats.new.to_h,
        cable:        CableStats.new.to_h,
        generated_at: Time.current.iso8601
      }
    end
  end
end
