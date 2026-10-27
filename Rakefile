require "bundler/setup"

require "bundler/gem_tasks"
require "rubocop/rake_task"
require "rspec/core/rake_task"
require "bundler/audit/task"

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)
Bundler::Audit::Task.new

desc "Run Brakeman against the engine code (dummy app excluded)"
task :brakeman do
  sh "bundle exec brakeman -q --no-pager --force-scan --skip-files spec/dummy/ -i config/brakeman.ignore"
end

desc "Run bundler-audit, brakeman, rubocop, and rspec (full CI suite)"
task ci: ["bundle:audit:update", "bundle:audit:check", :brakeman, :rubocop, :spec]

task default: :ci

namespace :dev do
  def dummy_env
    ENV["RAILS_ENV"] = "development"
    require File.expand_path("spec/dummy/config/environment", __dir__)
  end

  desc "Create and migrate the dummy app development database"
  task :setup do
    dummy_env
    ActiveRecord::Tasks::DatabaseTasks.root = File.expand_path("spec/dummy", __dir__)
    db_config = ActiveRecord::Base.configurations.find_db_config("development")
    ActiveRecord::Tasks::DatabaseTasks.create(db_config)
    load File.expand_path("spec/dummy/db/schema.rb", __dir__)
    puts "Development database ready."
  end

  desc "Seed the dummy app development database with fake data"
  task :seed do
    dummy_env
    load File.expand_path("spec/dummy/db/seeds.rb", __dir__)
  end

  desc "Reset and reseed the dummy app development database"
  task reset: [:setup, :seed]
end
