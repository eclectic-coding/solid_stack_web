module SolidStackWeb
  module ApplicationHelper
    def inline_styles
      dir = SolidStackWeb::Engine.root.join("app/assets/stylesheets/solid_stack_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
