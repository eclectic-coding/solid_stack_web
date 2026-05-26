require "net/http"
require "json"

module SolidStackWeb
  class AlertWebhook
    COOLDOWN_CACHE_KEY = "solid_stack_web/alert_webhook/cooldown"

    def self.check(queue_stats)
      new(queue_stats).check
    end

    def initialize(queue_stats)
      @queue_stats = queue_stats
    end

    def check
      return unless SolidStackWeb.alert_webhook_url
      return if on_cooldown?

      alerts = build_alerts
      return if alerts.empty?

      deliver(alerts)
      set_cooldown
    end

    private

    def build_alerts
      alerts = []

      if (threshold = SolidStackWeb.alert_failure_threshold)
        count = @queue_stats[:failed]
        alerts << { type: "failed_jobs", count: count, threshold: threshold } if count >= threshold
      end

      SolidStackWeb.alert_queue_thresholds.each do |queue_name, threshold|
        count = ::SolidQueue::ReadyExecution.where(queue_name: queue_name.to_s).count
        alerts << { type: "queue_depth", queue: queue_name.to_s, count: count, threshold: threshold } if count >= threshold
      end

      alerts
    end

    def deliver(alerts)
      payload = { alerts: alerts, generated_at: Time.current.iso8601 }
      uri = URI(SolidStackWeb.alert_webhook_url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                      open_timeout: 5, read_timeout: 5) do |http|
        request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
        request.body = payload.to_json
        http.request(request)
      end
    rescue StandardError
      # webhook delivery failures must not affect the response
    end

    def on_cooldown?
      Rails.cache.read(COOLDOWN_CACHE_KEY).present?
    end

    def set_cooldown
      Rails.cache.write(COOLDOWN_CACHE_KEY, Time.current.iso8601,
                        expires_in: SolidStackWeb.alert_webhook_cooldown)
    end
  end
end
