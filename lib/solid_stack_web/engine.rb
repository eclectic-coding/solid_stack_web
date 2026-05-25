require "pagy"
require "pagy/toolbox/paginators/method"
require "solid_queue"
require "solid_cache"
require "solid_cable"

module SolidStackWeb
  class Engine < ::Rails::Engine
    isolate_namespace SolidStackWeb

    config.i18n.load_path += Gem.find_files("pagy/locales/en.yml")

    initializer "solid_stack_web.mime_types" do
      Mime::Type.register "text/vnd.turbo-stream.html", :turbo_stream unless Mime[:turbo_stream]
    end

    initializer "solid_stack_web.pagy" do |app|
      app.config.after_initialize do
        Pagy::OPTIONS[:limit] = SolidStackWeb.page_size
      end
    end
  end
end
