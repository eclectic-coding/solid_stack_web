require "csv"

module SolidStackWeb
  class ApplicationController < ActionController::Base
    include Pagy::Method

    PERIOD_DURATIONS = { "1h" => 1.hour, "24h" => 24.hours, "7d" => 7.days }.freeze

    before_action :authenticate!
    around_action :with_locale
    around_action :with_database_connection

    rescue_from StandardError do |exception|
      raise exception if Rails.application.config.consider_all_requests_local
      render_internal_server_error
    end

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    helper_method :current_section

    private

    def current_section
      case controller_name
      when "jobs", "failed_jobs", "queues", "processes", "history", "scheduled_jobs", "recurring_tasks", "audit" then :queue
      when "cache", "cache_entries" then :cache
      when "cable" then :cable
      else :overview
      end
    end

    def with_locale
      available = SolidStackWeb.available_locales.map(&:to_s)
      locale = params[:locale].presence_in(available) ||
               session[:solid_stack_web_locale].presence_in(available) ||
               I18n.default_locale.to_s
      session[:solid_stack_web_locale] = locale
      I18n.with_locale(locale) { yield }
    end

    def with_database_connection
      config = SolidStackWeb.connects_to
      return yield unless config

      if config.key?(:reading) && config.key?(:writing)
        role = request.get? ? config[:reading] : config[:writing]
        ActiveRecord::Base.connected_to(role: role) { yield }
      else
        ActiveRecord::Base.connected_to(**config) { yield }
      end
    end

    def authenticate!
      return unless (auth = SolidStackWeb.authenticate)

      instance_exec(&auth) || request_basic_auth
    end

    def request_basic_auth
      request_http_basic_authentication("Solid Stack Dashboard")
    end

    def record_audit(action, job_class: nil, queue_name: nil, item_count: 1)
      AuditEvent.create!(
        action:     action,
        actor:      resolve_current_actor,
        job_class:  job_class,
        queue_name: queue_name,
        item_count: item_count
      )
    rescue => e
      Rails.logger.error("[SolidStackWeb] Audit log failed: #{e.message}")
    end

    def resolve_current_actor
      block = SolidStackWeb.current_actor
      return nil unless block

      instance_exec(&block)
    rescue => e
      Rails.logger.error("[SolidStackWeb] current_actor resolution failed: #{e.message}")
      nil
    end

    def render_not_found
      render "solid_stack_web/errors/not_found", status: :not_found
    end

    def render_internal_server_error
      render "solid_stack_web/errors/internal_server_error", status: :internal_server_error
    end
  end
end
