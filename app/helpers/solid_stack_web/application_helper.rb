module SolidStackWeb
  module ApplicationHelper
    def local_time(time, format: :short, placeholder: "—")
      return placeholder if time.nil?

      iso = time.utc.iso8601
      fallback = case format
      when :long     then time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
      when :relative then "#{time_ago_in_words(time)} ago"
      else                time.utc.strftime("%b %-d %H:%M UTC")
      end
      tag.time(fallback, datetime: iso,
               data: { controller: "timestamp", timestamp_format_value: format })
    end

    def format_cache_value(raw)
      str = raw.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
      parsed = JSON.parse(str)
      { label: "JSON", content: JSON.pretty_generate(parsed) }
    rescue JSON::ParserError, JSON::GeneratorError
      { label: "Text", content: str }
    end

    # Solid Cable stores payloads (and channel names) in a binary (bytea) column,
    # so ActiveRecord hands the view a string with ASCII-8BIT (BINARY) encoding.
    # Appending such a value — once it holds non-ASCII bytes (e.g. a "→" in a
    # Turbo Stream payload) and the UTF-8 output buffer already contains
    # non-ASCII text — raises Encoding::CompatibilityError. Re-tag the bytes as
    # UTF-8 (lossless; the underlying data is UTF-8 source text) before it
    # reaches the view. dup keeps the ActiveRecord attribute string unmutated.
    def to_utf8_text(value)
      value.to_s.dup.force_encoding("UTF-8")
    end

    def format_duration(seconds)
      return "—" if seconds.nil?
      return "#{(seconds * 1000).round}ms" if seconds < 1
      s = seconds.to_i
      return "#{sprintf("%g", seconds.round(1))}s" if s < 60
      return "#{s / 60}m #{s % 60}s"      if s < 3600

      "#{s / 3600}h #{(s % 3600) / 60}m"
    end

    def cache_entries_timeline_svg(timeline)
      build_sparkline_svg(
        Struct.new(:buckets, :max).new(timeline.entry_buckets, timeline.entry_max),
        css_class: "sqw-sparkline sqw-sparkline--lg",
        aria_label: t("solid_stack_web.helpers.cache_entry_this_hour", count: 0).gsub(/\d+/, "…")
      ) do |count, i|
        hours_ago = CacheTimeline::HOURS - 1 - i
        if hours_ago.zero?
          t("solid_stack_web.helpers.cache_entry_this_hour", count: count)
        else
          t("solid_stack_web.helpers.cache_entry_hours_ago", count: count, hours: hours_ago)
        end
      end
    end

    def cache_bytes_timeline_svg(timeline)
      build_sparkline_svg(
        Struct.new(:buckets, :max).new(timeline.byte_buckets, timeline.byte_max),
        css_class: "sqw-sparkline sqw-sparkline--lg",
        aria_label: t("solid_stack_web.cache.bytes_written")
      ) do |bytes, i|
        hours_ago = CacheTimeline::HOURS - 1 - i
        size = number_to_human_size(bytes)
        if hours_ago.zero?
          t("solid_stack_web.helpers.cache_size_this_hour", size: size)
        else
          t("solid_stack_web.helpers.cache_size_hours_ago", size: size, hours: hours_ago)
        end
      end
    end

    def cable_messages_timeline_svg(timeline)
      build_sparkline_svg(
        Struct.new(:buckets, :max).new(timeline.message_buckets, timeline.message_max),
        css_class: "sqw-sparkline sqw-sparkline--lg",
        aria_label: t("solid_stack_web.cable.messages_timeline")
      ) do |count, i|
        hours_ago = CableTimeline::HOURS - 1 - i
        if hours_ago.zero?
          t("solid_stack_web.helpers.cable_message_this_hour", count: count)
        else
          t("solid_stack_web.helpers.cable_message_hours_ago", count: count, hours: hours_ago)
        end
      end
    end

    def throughput_sparkline_svg(sparkline)
      build_sparkline_svg(sparkline, aria_label: t("solid_stack_web.dashboard.throughput_label")) do |count, i|
        hours_ago = SolidStackWeb::ThroughputSparkline::HOURS - i
        if hours_ago == 1
          t("solid_stack_web.helpers.throughput_last_hour", count: count)
        else
          t("solid_stack_web.helpers.throughput_hours_ago", count: count, from: hours_ago, to: hours_ago - 1)
        end
      end
    end

    def queue_depth_sparkline_svg(sparkline)
      build_sparkline_svg(sparkline, css_class: "sqw-sparkline sqw-sparkline--sm",
                                     aria_label: t("solid_stack_web.queues.col_depth")) do |count, i|
        hours_ago = SolidStackWeb::QueueDepthSparkline::HOURS - 1 - i
        if hours_ago.zero?
          t("solid_stack_web.helpers.queue_depth_now", count: count)
        else
          t("solid_stack_web.helpers.queue_depth_hours_ago", count: count, hours: hours_ago)
        end
      end
    end

    def audit_action_badge_class(action)
      case action
      when /discard/ then "sqw-badge--failed"
      when /retry/   then "sqw-badge--scheduled"
      when "queue_paused"  then "sqw-badge--blocked"
      when "queue_resumed" then "sqw-badge--ready"
      end
    end

    def sort_header_th(label, col, url_proc, current_sort:, current_dir:)
      is_active = current_sort == col
      next_dir  = (is_active && current_dir == "desc") ? "asc" : "desc"
      indicator = is_active ? content_tag(:span, current_dir == "desc" ? "↓" : "↑", class: "sqw-sort-indicator") : nil
      tag_opts  = { scope: "col" }
      tag_opts[:"aria-sort"] = is_active ? (current_dir == "asc" ? "ascending" : "descending") : nil if is_active
      content_tag(:th, **tag_opts) do
        link_to(url_proc.call(sort: col, direction: next_dir)) do
          safe_join([label, indicator].compact)
        end
      end
    end

    def failed_job_sparkline_svg(sparkline)
      build_sparkline_svg(sparkline, aria_label: t("solid_stack_web.dashboard.failures_label")) do |count, i|
        hours_ago = SolidStackWeb::FailedJobSparkline::HOURS - i
        if hours_ago == 1
          t("solid_stack_web.helpers.failure_last_hour", count: count)
        else
          t("solid_stack_web.helpers.failure_hours_ago", count: count, from: hours_ago, to: hours_ago - 1)
        end
      end
    end

    private

    def build_sparkline_svg(sparkline, css_class: "sqw-sparkline", aria_label: nil, &tooltip_text)
      buckets = sparkline.buckets
      peak    = [sparkline.max.to_f, 1.0].max
      h       = 40
      bar_w   = 8
      gap     = 2
      total_w = buckets.size * (bar_w + gap) - gap

      bars = buckets.each_with_index.map do |count, i|
        x       = i * (bar_w + gap)
        bar_h   = [(count / peak * (h - 4)).round, 2].max
        y       = h - bar_h
        opacity = count.zero? ? "0.18" : "1"
        tip     = tooltip_text.call(count, i)
        attrs = %( x="#{x}" y="#{y}" width="#{bar_w}" height="#{bar_h}" rx="1") +
                %( fill="currentColor" opacity="#{opacity}") +
                %( data-sparkline-tooltip-target="bar") +
                %( data-tip="#{ERB::Util.html_escape(tip)}") +
                %( data-action="mouseenter->sparkline-tooltip#show mouseleave->sparkline-tooltip#hide")
        "<rect#{attrs}></rect>"
      end.join

      content_tag(:svg, bars.html_safe,
                  viewBox: "0 0 #{total_w} #{h}",
                  preserveAspectRatio: "none",
                  class: css_class,
                  role: "img",
                  "aria-label": aria_label)
    end

    public

    def inline_styles
      dir = SolidStackWeb::Engine.root.join("app/assets/stylesheets/solid_stack_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
