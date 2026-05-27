require "pagy"
require "pagy/toolbox/paginators/method"
require "solid_queue"
require "solid_cache"
require "solid_cable"
require "turbo-rails"
require "importmap-rails"

module SolidStackWeb
  class Engine < ::Rails::Engine
    isolate_namespace SolidStackWeb

    config.i18n.load_path += Gem.find_files("pagy/locales/en.yml")

    initializer "solid_stack_web.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
      end
    end

    initializer "solid_stack_web.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    initializer "solid_stack_web.deprecator" do |app|
      app.deprecators[:solid_stack_web] = SolidStackWeb.deprecator
    end

    initializer "solid_stack_web.pagy" do |app|
      app.config.after_initialize do
        Pagy::OPTIONS[:limit] = SolidStackWeb.page_size
      end
    end
  end
end
