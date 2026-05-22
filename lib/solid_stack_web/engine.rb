require "pagy"
require "pagy/toolbox/paginators/method"

module SolidStackWeb
  class Engine < ::Rails::Engine
    isolate_namespace SolidStackWeb

    config.i18n.load_path += Gem.find_files("pagy/locales/en.yml")

    initializer "solid_stack_web.pagy" do |app|
      app.config.after_initialize do
        Pagy::OPTIONS[:limit] = SolidStackWeb.page_size
      end
    end
  end
end
