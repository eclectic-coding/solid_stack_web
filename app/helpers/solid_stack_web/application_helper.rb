module SolidStackWeb
  module ApplicationHelper
    def format_duration(seconds)
      s = seconds.to_i
      return "#{s}s"          if s < 60
      return "#{s / 60}m #{s % 60}s" if s < 3600

      "#{s / 3600}h #{(s % 3600) / 60}m"
    end

    def inline_styles
      dir = SolidStackWeb::Engine.root.join("app/assets/stylesheets/solid_stack_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
