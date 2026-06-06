require "solid_stack_web/version"
require "solid_stack_web/engine"

module SolidStackWeb
  class << self
    attr_writer :page_size, :connects_to, :slow_job_threshold,
                :alert_webhook_url, :alert_webhook_cooldown,
                :alert_failure_threshold, :alert_queue_thresholds,
                :alert_slow_job_count_threshold, :alert_stale_process_threshold,
                :dashboard_refresh_interval, :default_refresh_interval,
                :search_results_limit, :allow_value_preview,
                :available_locales

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

    def alert_slow_job_count_threshold
      @alert_slow_job_count_threshold
    end

    def alert_stale_process_threshold
      @alert_stale_process_threshold
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

    def available_locales
      @available_locales || %i[en es]
    end

    # Returns the path at which the engine is mounted in the host application,
    # derived automatically from the host's routes. Host apps can use this to
    # build links to the dashboard without hardcoding the mount path.
    #
    #   link_to "Dashboard", SolidStackWeb.mount_path
    #
    def mount_path
      route = Rails.application.routes.routes.find do |r|
        r.app.respond_to?(:app) && r.app.app == SolidStackWeb::Engine
      end
      route&.path&.spec&.to_s&.sub(%r{\(.*\)\z}, "") || "/"
    end

    def configure
      yield self
    end

    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end

    def current_actor(&block)
      @current_actor = block if block_given?
      @current_actor
    end

    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("1.0", "SolidStackWeb")
    end

    private

    # Define a deprecated writer for a renamed config key.
    # The old writer issues a deprecation warning and forwards to the new key.
    #
    # Usage (add entries here as keys are renamed before 1.0):
    #   deprecated_config :old_key, :new_key
    def deprecated_config(old_key, new_key)
      singleton_class.define_method(:"#{old_key}=") do |value|
        deprecator.warn(
          "config.#{old_key}= is deprecated and will be removed in SolidStackWeb 1.0. " \
          "Use config.#{new_key}= instead.",
          caller_locations
        )
        public_send(:"#{new_key}=", value)
      end
    end
  end
end
