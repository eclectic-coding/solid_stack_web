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
  "Net::ReadTimeout: Net::ReadTimeout with #<TCPSocket:(closed)>",
  "ActiveRecord::RecordNotFound: Couldn't find User with 'id'=42",
  "Faraday::ConnectionFailed: Failed to open TCP connection to api.example.com:443",
  "RuntimeError: Rate limit exceeded — retry after 60s",
  "JSON::ParserError: unexpected token at '<html>'",
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
    job = SolidQueue::Job.create!(
      class_name: JOB_CLASSES.sample,
      queue_name: QUEUES.sample,
      arguments: [{ record_id: rand(1..100) }].to_json,
      priority: 0,
      active_job_id: SecureRandom.uuid
    )
    SolidQueue::FailedExecution.create!(job: job, error: ERRORS.sample)
  end
ensure
  SolidQueue::Job.set_callback(:create, :after, :prepare_for_execution)
  SolidQueue::BlockedExecution.set_callback(:create, :before, :set_expires_at)
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

# ── Summary ───────────────────────────────────────────────────────────────────

puts ""
puts "Seeded:"
puts "  Solid Queue — #{SolidQueue::Job.count} jobs " \
     "(#{SolidQueue::ReadyExecution.count} ready, " \
     "#{SolidQueue::ScheduledExecution.count} scheduled, " \
     "#{SolidQueue::ClaimedExecution.count} claimed, " \
     "#{SolidQueue::BlockedExecution.count} blocked, " \
     "#{SolidQueue::FailedExecution.count} failed), " \
     "#{SolidQueue::Process.count} processes"
puts "  Solid Cache  — #{SolidCache::Entry.count} entries"
puts "  Solid Cable  — #{SolidCable::Message.count} messages across #{SolidCable::Message.distinct.count(:channel)} channels"