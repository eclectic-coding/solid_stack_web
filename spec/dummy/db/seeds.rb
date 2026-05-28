JOB_CLASSES = %w[
  EmailNotificationJob
  UserReportJob
  DataImportJob
  ImageProcessingJob
  WebhookDeliveryJob
  DailyCleanupJob
  SyncInventoryJob
  GeneratePdfJob
  SendDigestJob
  RecalculateScoresJob
].freeze

QUEUES = %w[default mailers critical low_priority].freeze

ERRORS = [
  { exception_class: "Net::ReadTimeout",
    message: "Net::ReadTimeout with #<TCPSocket:(closed)>",
    backtrace: ["lib/net/http.rb:1234", "app/jobs/webhook_delivery_job.rb:12"] },
  { exception_class: "ActiveRecord::RecordNotFound",
    message: "Couldn't find User with 'id'=42",
    backtrace: ["app/controllers/users_controller.rb:15"] },
  { exception_class: "Faraday::ConnectionFailed",
    message: "Failed to open TCP connection to api.example.com:443",
    backtrace: ["app/services/api_client.rb:42", "app/jobs/sync_inventory_job.rb:8"] },
  { exception_class: "RuntimeError",
    message: "Rate limit exceeded — retry after 60s",
    backtrace: ["app/jobs/send_digest_job.rb:31"] },
  { exception_class: "JSON::ParserError",
    message: "unexpected token at '<html>'",
    backtrace: ["app/jobs/data_import_job.rb:22"] },
].freeze

# ── Solid Queue: Processes ────────────────────────────────────────────────────

puts "  processes..."

supervisor = SolidQueue::Process.create!(
  kind: "Supervisor",
  name: "supervisor-#{SecureRandom.hex(4)}",
  pid: 12_000,
  hostname: "web-01.local",
  last_heartbeat_at: 5.seconds.ago,
  metadata: { queues: QUEUES }.to_json
)

workers = Array.new(3) do |i|
  SolidQueue::Process.create!(
    kind: "Worker",
    name: "worker-#{i + 1}-#{SecureRandom.hex(4)}",
    pid: 12_001 + i,
    hostname: "web-01.local",
    supervisor_id: supervisor.id,
    last_heartbeat_at: rand(1..10).seconds.ago,
    metadata: { queues: QUEUES, threads: 5 }.to_json
  )
end

SolidQueue::Process.create!(
  kind: "Dispatcher",
  name: "dispatcher-#{SecureRandom.hex(4)}",
  pid: 12_010,
  hostname: "web-01.local",
  supervisor_id: supervisor.id,
  last_heartbeat_at: 3.seconds.ago,
  metadata: { batch_size: 500, polling_interval: 1 }.to_json
)

# ── Solid Queue: Ready jobs ───────────────────────────────────────────────────

puts "  ready jobs..."

15.times do
  SolidQueue::Job.create!(
    class_name: JOB_CLASSES.sample,
    queue_name: QUEUES.sample,
    arguments: [{ user_id: rand(1..1000) }].to_json,
    priority: rand(0..10),
    active_job_id: SecureRandom.uuid
  )
end

# ── Solid Queue: Scheduled jobs ───────────────────────────────────────────────

puts "  scheduled jobs..."

8.times do |i|
  SolidQueue::Job.create!(
    class_name: JOB_CLASSES.sample,
    queue_name: QUEUES.sample,
    arguments: [{ report_id: rand(1..500) }].to_json,
    priority: rand(0..5),
    active_job_id: SecureRandom.uuid,
    scheduled_at: (i + 1).hours.from_now
  )
end

# ── Solid Queue: Claimed / blocked / failed (skip dispatch callback) ──────────

SolidQueue::Job.skip_callback(:create, :after, :prepare_for_execution)
# set_expires_at calls job.concurrency_duration which constantizes class_name — skip it since
# we provide expires_at directly and the job classes don't exist in the dummy app.
SolidQueue::BlockedExecution.skip_callback(:create, :before, :set_expires_at)

begin
  puts "  claimed jobs..."
  workers.each_with_index do |worker, i|
    job = SolidQueue::Job.create!(
      class_name: JOB_CLASSES.sample,
      queue_name: QUEUES.sample,
      arguments: [{ batch: i }].to_json,
      priority: 0,
      active_job_id: SecureRandom.uuid
    )
    SolidQueue::ClaimedExecution.create!(job: job, process_id: worker.id)
  end

  puts "  blocked jobs..."
  concurrency_key = "EmailNotificationJob/user-7"
  3.times do
    job = SolidQueue::Job.create!(
      class_name: "EmailNotificationJob",
      queue_name: "mailers",
      arguments: [{ user_id: 7 }].to_json,
      priority: 0,
      active_job_id: SecureRandom.uuid,
      concurrency_key: concurrency_key
    )
    SolidQueue::BlockedExecution.create!(
      job: job,
      queue_name: "mailers",
      priority: 0,
      concurrency_key: concurrency_key,
      expires_at: 10.minutes.from_now
    )
  end

  puts "  failed jobs..."
  5.times do
    class_name = JOB_CLASSES.sample
    job = SolidQueue::Job.create!(
      class_name: class_name,
      queue_name: QUEUES.sample,
      arguments: { "job_class" => class_name, "arguments" => [{ "record_id" => rand(1..100) }],
                   "executions" => 1, "exception_executions" => {} },
      priority: 0,
      active_job_id: SecureRandom.uuid
    )
    SolidQueue::FailedExecution.create!(job: job, error: ERRORS.sample)
  end
ensure
  SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
  SolidQueue::BlockedExecution.set_callback(:create, :before, :set_expires_at)
end

# ── Solid Queue: Finished jobs (history) ─────────────────────────────────────

puts "  finished jobs..."

[
  { age: 20.minutes, duration: 12 },
  { age: 45.minutes, duration: 3 },
  { age: 2.hours,    duration: 87 },
  { age: 6.hours,    duration: 5 },
  { age: 18.hours,   duration: 210 },
  { age: 2.days,     duration: 44 },
  { age: 4.days,     duration: 9 },
  { age: 8.days,     duration: 130 },
].each do |attrs|
  finished_at = attrs[:age].ago
  job = SolidQueue::Job.new(
    class_name: JOB_CLASSES.sample,
    queue_name: QUEUES.sample,
    arguments: [{ record_id: rand(1..500) }].to_json,
    priority: rand(0..5),
    active_job_id: SecureRandom.uuid
  )
  job.finished_at = finished_at
  job.created_at  = finished_at - attrs[:duration].seconds
  job.updated_at  = finished_at
  job.save!(validate: false)
end

# ── Solid Queue: Recurring tasks ─────────────────────────────────────────────

puts "  recurring tasks..."

[
  { key: "nightly-cleanup",    schedule: "0 2 * * *",   command: "DailyCleanupJob.perform_later",    queue_name: "default",  description: "Nightly database cleanup", static: true },
  { key: "daily-user-report",  schedule: "0 8 * * *",   command: "UserReportJob.perform_later",       queue_name: "mailers",  description: "Send daily user summary",  static: true },
  { key: "hourly-sync",        schedule: "0 * * * *",   command: "SyncInventoryJob.perform_later",    queue_name: "default",  description: nil,                        static: true },
  { key: "weekly-digest",      schedule: "0 9 * * 1",   command: "SendDigestJob.perform_later",       queue_name: "mailers",  description: "Weekly digest email",      static: false },
].each do |attrs|
  SolidQueue::RecurringTask.create!(attrs)
end

# ── Solid Cache ───────────────────────────────────────────────────────────────

puts "  cache entries..."

{
  "users/1/profile"         => { name: "Alice", email: "alice@example.com", role: "admin" }.to_json,
  "users/2/profile"         => { name: "Bob",   email: "bob@example.com",   role: "member" }.to_json,
  "posts/recent"            => Array.new(10) { { id: rand(1..1000), title: "Post #{rand(100)}" } }.to_json,
  "site/settings"           => { theme: "dark", locale: "en", timezone: "UTC" }.to_json,
  "stats/daily"             => { visits: 4821, signups: 34, revenue: 1290.50 }.to_json,
  "nav/menu"                => %w[Home About Pricing Blog Contact].to_json,
  "products/featured"       => Array.new(5) { { id: rand(1..200), name: "Product #{rand(100)}" } }.to_json,
  "api/rate_limit/user_42"  => { remaining: 87, reset_at: 1.hour.from_now.to_i }.to_json,
}.each do |key, value|
  SolidCache::Entry.write(key, value)
end

# ── Solid Cable ───────────────────────────────────────────────────────────────

puts "  cable messages..."

{
  "notifications:user_1" => [
    { type: "notification", message: "You have a new follower" },
    { type: "notification", message: "Your export is ready to download" },
  ],
  "notifications:user_2" => [
    { type: "notification", message: "Alice commented on your post" },
  ],
  "presence:lobby" => [
    { type: "presence", user: "alice", status: "online" },
    { type: "presence", user: "bob",   status: "online" },
    { type: "presence", user: "carol", status: "away" },
  ],
  "chat:general" => [
    { type: "message", text: "Hey everyone!", user: "bob" },
    { type: "message", text: "Good morning 👋", user: "alice" },
    { type: "message", text: "Anyone seen the deploy notes?", user: "dave" },
  ],
}.each do |channel, messages|
  messages.each { |payload| SolidCable::Message.broadcast(channel, payload.to_json) }
end

# ── Audit log ────────────────────────────────────────────────────────────────

puts "  audit events..."

ACTORS = %w[alice@example.com bob@example.com carol@example.com].freeze

[
  { action: "job_discarded",        actor: ACTORS.sample, job_class: "WebhookDeliveryJob",  queue_name: "default",      created_at: 2.minutes.ago  },
  { action: "job_discarded",        actor: ACTORS.sample, job_class: "DataImportJob",        queue_name: "low_priority", created_at: 15.minutes.ago },
  { action: "jobs_discarded",       actor: ACTORS.sample, job_class: nil,                    queue_name: nil,            item_count: 7, created_at: 1.hour.ago   },
  { action: "failed_job_retried",   actor: ACTORS.sample, job_class: "UserReportJob",        queue_name: "mailers",      created_at: 30.minutes.ago },
  { action: "failed_job_retried",   actor: ACTORS.sample, job_class: "SyncInventoryJob",     queue_name: "default",      created_at: 3.hours.ago    },
  { action: "failed_jobs_retried",  actor: ACTORS.sample, job_class: nil,                    queue_name: nil,            item_count: 3, created_at: 5.hours.ago  },
  { action: "failed_job_discarded", actor: ACTORS.sample, job_class: "GeneratePdfJob",       queue_name: "critical",     created_at: 45.minutes.ago },
  { action: "failed_jobs_discarded",actor: ACTORS.sample, job_class: nil,                    queue_name: nil,            item_count: 2, created_at: 2.hours.ago  },
  { action: "queue_paused",         actor: ACTORS.sample, job_class: nil,                    queue_name: "critical",     created_at: 20.minutes.ago },
  { action: "queue_resumed",        actor: ACTORS.sample, job_class: nil,                    queue_name: "critical",     created_at: 10.minutes.ago },
  { action: "queue_paused",         actor: nil,           job_class: nil,                    queue_name: "low_priority", created_at: 4.days.ago     },
  { action: "job_discarded",        actor: nil,           job_class: "RecalculateScoresJob", queue_name: "default",      created_at: 3.days.ago     },
].each do |attrs|
  SolidStackWeb::AuditEvent.create!(attrs)
end

# ── Summary ───────────────────────────────────────────────────────────────────

puts ""
puts "Seeded:"
puts "  Solid Queue — #{SolidQueue::Job.count} jobs " \
     "(#{SolidQueue::ReadyExecution.count} ready, " \
     "#{SolidQueue::ScheduledExecution.count} scheduled, " \
     "#{SolidQueue::ClaimedExecution.count} claimed, " \
     "#{SolidQueue::BlockedExecution.count} blocked, " \
     "#{SolidQueue::FailedExecution.count} failed, " \
     "#{SolidQueue::Job.where.not(finished_at: nil).count} finished), " \
     "#{SolidQueue::Process.count} processes, " \
     "#{SolidQueue::RecurringTask.count} recurring tasks"
puts "  Solid Cache  — #{SolidCache::Entry.count} entries"
puts "  Solid Cable  — #{SolidCable::Message.count} messages across #{SolidCable::Message.distinct.count(:channel)} channels"
puts "  Audit log    — #{SolidStackWeb::AuditEvent.count} events"