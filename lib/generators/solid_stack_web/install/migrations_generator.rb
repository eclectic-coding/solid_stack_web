require "rails/generators/base"
require "rails/generators/migration"

module SolidStackWeb
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Generates the solid_stack_web_audit_events migration"

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration_file
        migration_template "create_solid_stack_web_audit_events.rb.tt",
                           "db/migrate/create_solid_stack_web_audit_events.rb"
      end
    end
  end
end
