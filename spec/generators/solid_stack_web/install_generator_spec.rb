require "rails_helper"
require "rails/generators"
require "rails/generators/testing/assertions"
require "rails/generators/testing/setup_and_teardown"
require "rails/generators/testing/behavior"
require "generators/solid_stack_web/install/install_generator"

RSpec.describe SolidStackWeb::Generators::InstallGenerator do
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests SolidStackWeb::Generators::InstallGenerator
  destination File.expand_path("../../../tmp/generator_test", __dir__)

  before do
    prepare_destination
    mkdir_p File.join(destination_root, "config")
    File.write(File.join(destination_root, "config/routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY
  end

  describe "initializer" do
    before { run_generator }

    it "creates the initializer file" do
      assert_file "config/initializers/solid_stack_web.rb"
    end

    it "includes the configure block" do
      assert_file "config/initializers/solid_stack_web.rb",
                  /SolidStackWeb\.configure do \|config\|/
    end

    it "documents the authenticate option" do
      assert_file "config/initializers/solid_stack_web.rb", /config\.authenticate/
    end

    it "documents the page_size option" do
      assert_file "config/initializers/solid_stack_web.rb", /config\.page_size/
    end

    it "documents the slow_job_threshold option" do
      assert_file "config/initializers/solid_stack_web.rb", /config\.slow_job_threshold/
    end

    it "documents the alert_webhook_url option" do
      assert_file "config/initializers/solid_stack_web.rb", /config\.alert_webhook_url/
    end

    it "documents the allow_value_preview option" do
      assert_file "config/initializers/solid_stack_web.rb", /config\.allow_value_preview/
    end
  end

  describe "routes" do
    before { run_generator }

    it "injects the mount line into routes.rb" do
      assert_file "config/routes.rb",
                  /mount SolidStackWeb::Engine, at: "\/solid_stack"/
    end
  end
end
