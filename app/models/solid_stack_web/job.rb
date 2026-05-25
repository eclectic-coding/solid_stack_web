module SolidStackWeb
  class Job
    STATUSES = %w[ready scheduled claimed blocked].freeze

    EXECUTION_MODELS = {
      "ready"     => SolidQueue::ReadyExecution,
      "scheduled" => SolidQueue::ScheduledExecution,
      "claimed"   => SolidQueue::ClaimedExecution,
      "blocked"   => SolidQueue::BlockedExecution
    }.freeze

    DISCARDABLE = %w[ready scheduled blocked].freeze

    TAB_LABELS = {
      "ready"     => "Ready",
      "scheduled" => "Scheduled",
      "claimed"   => "Running",
      "blocked"   => "Blocked"
    }.freeze
  end
end
