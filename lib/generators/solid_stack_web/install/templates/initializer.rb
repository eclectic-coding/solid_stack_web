SolidStackWeb.configure do |config|
  # Authentication — block runs in controller context.
  # Return a truthy value to allow access; falsy falls back to HTTP Basic auth.
  # If omitted entirely, the dashboard is open to anyone.
  #
  #   config.authenticate do
  #     current_user&.admin?
  #   end

  # Number of records shown per paginated page (default: 25).
  # config.page_size = 25

  # Database connection — pass a connects_to hash when Solid Queue / Cache / Cable
  # live on a separate database from your primary.
  #
  #   config.connects_to = { database: { writing: :queue, reading: :queue } }

  # Slow-job threshold in seconds (default: nil — stat hidden).
  # When set, the dashboard shows a "Slow (24h)" count on the overview card
  # for finished jobs whose wall time exceeded this value.
  # config.slow_job_threshold = 30

  # Auto-refresh intervals in milliseconds.
  # config.dashboard_refresh_interval = 5_000   # overview dashboard
  # config.default_refresh_interval   = 10_000  # jobs, processes, history

  # Maximum number of results returned by the search feature (default: 25).
  # config.search_results_limit = 25

  # Show the raw serialised value on the cache entry detail page (default: false).
  # Disable for stores that contain sensitive data.
  # config.allow_value_preview = false

  # Link to the dashboard from anywhere in your app without hardcoding the path:
  #
  #   link_to "Queue Dashboard", SolidStackWeb.mount_path
  #
  # SolidStackWeb.mount_path is derived automatically from your routes — no
  # configuration needed.

  # Alert webhook — POST to this URL when a threshold is breached.
  # Delivery failures are silently swallowed; configure a cooldown to avoid storms.
  #
  # config.alert_webhook_url              = "https://hooks.example.com/my-alert"
  # config.alert_failure_threshold        = 10      # fire when failed jobs >= this
  # config.alert_queue_thresholds         = {       # fire when a queue's ready depth >= value
  #   "critical" => 50,
  #   "default"  => 500
  # }
  # config.alert_slow_job_count_threshold = 3       # fire when N+ claimed jobs exceed slow_job_threshold duration
  # config.alert_webhook_cooldown         = 3600    # seconds between repeat alerts
end
