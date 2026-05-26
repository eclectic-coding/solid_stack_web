require "solid_stack_web/version"
require "solid_stack_web/engine"

module SolidStackWeb
  class << self
    attr_writer :page_size, :connects_to, :slow_job_threshold,
                :alert_webhook_url, :alert_webhook_cooldown,
                :alert_failure_threshold, :alert_queue_thresholds,
                :dashboard_refresh_interval, :default_refresh_interval,
                :search_results_limit, :allow_value_preview

    def page_size
      @page_size || 25
    end

    def connects_to
      @connects_to
    end

    def slow_job_threshold
      @slow_job_threshold
    end

    def alert_webhook_url
      @alert_webhook_url
    end

    def alert_webhook_cooldown
      @alert_webhook_cooldown || 3600
    end

    def alert_failure_threshold
      @alert_failure_threshold
    end

    def alert_queue_thresholds
      @alert_queue_thresholds || {}
    end

    def dashboard_refresh_interval
      @dashboard_refresh_interval || 5_000
    end

    def default_refresh_interval
      @default_refresh_interval || 10_000
    end

    def search_results_limit
      @search_results_limit || 25
    end

    def allow_value_preview
      @allow_value_preview || false
    end

    def configure
      yield self
    end

    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end
  end
end
