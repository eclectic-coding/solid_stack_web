module SolidStackWeb
  class StatsController < ApplicationController
    SORTABLE_COLUMNS = %w[class_name count avg p50 p95 p99 stddev min max].freeze

    def index
      @sort      = params[:sort].presence_in(SORTABLE_COLUMNS) || "p95"
      @direction = params[:direction] == "asc" ? "asc" : "desc"

      jobs   = SolidQueue::Job.where.not(finished_at: nil).select(:class_name, :created_at, :finished_at)
      @stats = build_stats(jobs)
      @stats.sort_by! { |row| row[@sort.to_sym] || 0 }
      @stats.reverse! if @direction == "desc"
    end

    private

    def build_stats(jobs)
      jobs.group_by(&:class_name).map do |class_name, group|
        durations = group.map { |j| (j.finished_at - j.created_at).to_f }.sort
        count     = durations.size
        avg = durations.sum / count
        {
          class_name: class_name,
          count:      count,
          avg:        avg,
          min:        durations.first,
          max:        durations.last,
          p50:        percentile(durations, 50),
          p95:        percentile(durations, 95),
          p99:        percentile(durations, 99),
          stddev:     stddev(durations, avg)
        }
      end
    end

    def percentile(sorted, pct)
      return 0.0 if sorted.empty?
      k = (sorted.size - 1) * pct / 100.0
      sorted[k.floor] + (sorted[k.ceil] - sorted[k.floor]) * (k - k.floor)
    end

    def stddev(durations, avg)
      return 0.0 if durations.size < 2
      variance = durations.sum { |d| (d - avg)**2 } / durations.size
      Math.sqrt(variance)
    end
  end
end
