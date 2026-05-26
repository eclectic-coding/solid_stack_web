require "rails/generators/base"

module SolidStackWeb
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a SolidStackWeb initializer and mounts the engine in routes.rb"

      def create_initializer
        template "initializer.rb", "config/initializers/solid_stack_web.rb"
      end

      def mount_engine
        route 'mount SolidStackWeb::Engine, at: "/solid_stack"'
      end
    end
  end
end
