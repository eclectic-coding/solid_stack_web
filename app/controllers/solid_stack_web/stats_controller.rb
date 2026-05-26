module SolidStackWeb
  class StatsController < ApplicationController
    SORTABLE_COLUMNS = %w[class_name count avg p50 p95 min max].freeze

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
        {
          class_name: class_name,
          count:      count,
          avg:        durations.sum / count,
          min:        durations.first,
          max:        durations.last,
          p50:        percentile(durations, 50),
          p95:        percentile(durations, 95)
        }
      end
    end

    def percentile(sorted, pct)
      return 0.0 if sorted.empty?
      k = (sorted.size - 1) * pct / 100.0
      sorted[k.floor] + (sorted[k.ceil] - sorted[k.floor]) * (k - k.floor)
    end
  end
end