module SolidStackWeb
  module ApplicationHelper
    def format_duration(seconds)
      return "—" if seconds.nil?
      return "#{(seconds * 1000).round}ms" if seconds < 1
      s = seconds.to_i
      return "#{sprintf("%g", seconds.round(1))}s" if s < 60
      return "#{s / 60}m #{s % 60}s"      if s < 3600

      "#{s / 3600}h #{(s % 3600) / 60}m"
    end

    def throughput_sparkline_svg(sparkline)
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
        hours_ago = SolidStackWeb::ThroughputSparkline::HOURS - i
        tooltip = if hours_ago == 1
          "#{count} #{count == 1 ? "job" : "jobs"} in the last hour"
        else
          "#{count} #{count == 1 ? "job" : "jobs"} (#{hours_ago}h–#{hours_ago - 1}h ago)"
        end
        %(<rect x="#{x}" y="#{y}" width="#{bar_w}" height="#{bar_h}" rx="1" fill="currentColor" opacity="#{opacity}"><title>#{ERB::Util.html_escape(tooltip)}</title></rect>)
      end.join

      content_tag(:svg, bars.html_safe,
                  viewBox: "0 0 #{total_w} #{h}",
                  preserveAspectRatio: "none",
                  class: "sqw-sparkline",
                  role: "img",
                  "aria-label": "Throughput over the last 12 hours")
    end

    def inline_styles
      dir = SolidStackWeb::Engine.root.join("app/assets/stylesheets/solid_stack_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
