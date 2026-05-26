module SolidStackWeb
  module ApplicationHelper
    def format_cache_value(raw)
      str = raw.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
      parsed = JSON.parse(str)
      { label: "JSON", content: JSON.pretty_generate(parsed) }
    rescue JSON::ParserError, JSON::GeneratorError
      { label: "Text", content: str }
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
        aria_label: "Cache entries written over the last 24 hours"
      ) do |count, i|
        hours_ago = CacheTimeline::HOURS - 1 - i
        hours_ago.zero? ? "#{count} #{"entry".then { |w| count == 1 ? w : "entries" }} this hour" \
                        : "#{count} #{"entry".then { |w| count == 1 ? w : "entries" }} #{hours_ago}h ago"
      end
    end

    def cache_bytes_timeline_svg(timeline)
      build_sparkline_svg(
        Struct.new(:buckets, :max).new(timeline.byte_buckets, timeline.byte_max),
        css_class: "sqw-sparkline sqw-sparkline--lg",
        aria_label: "Cache bytes written over the last 24 hours"
      ) do |bytes, i|
        hours_ago = CacheTimeline::HOURS - 1 - i
        size = number_to_human_size(bytes)
        hours_ago.zero? ? "#{size} written this hour" : "#{size} written #{hours_ago}h ago"
      end
    end

    def throughput_sparkline_svg(sparkline)
      build_sparkline_svg(sparkline, aria_label: "Throughput over the last 12 hours") do |count, i|
        hours_ago = SolidStackWeb::ThroughputSparkline::HOURS - i
        if hours_ago == 1
          "#{count} #{count == 1 ? "job" : "jobs"} in the last hour"
        else
          "#{count} #{count == 1 ? "job" : "jobs"} (#{hours_ago}h–#{hours_ago - 1}h ago)"
        end
      end
    end

    def queue_depth_sparkline_svg(sparkline)
      build_sparkline_svg(sparkline, css_class: "sqw-sparkline sqw-sparkline--sm",
                                     aria_label: "Queue depth over the last 12 hours") do |count, i|
        hours_ago = SolidStackWeb::QueueDepthSparkline::HOURS - 1 - i
        jobs_word = count == 1 ? "job" : "jobs"
        hours_ago.zero? ? "#{count} ready #{jobs_word} now" : "#{count} ready #{jobs_word} #{hours_ago}h ago"
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
