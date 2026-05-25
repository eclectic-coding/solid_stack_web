require_relative "lib/solid_stack_web/version"

Gem::Specification.new do |spec|
  spec.name        = "solid_stack_web"
  spec.version     = SolidStackWeb::VERSION
  spec.authors     = ["Chuck Smith"]
  spec.email       = ["eclectic-coding@users.noreply.github.com"]
  spec.homepage    = "https://github.com/eclectic-coding/solid_stack_web"
  spec.summary     = "A unified Rails engine dashboard for Solid Queue, Solid Cache, and Solid Cable."
  spec.description = "Mount SolidStackWeb in any Rails app using the Solid Stack to get a single " \
                     "dashboard covering Solid Queue job monitoring, Solid Cache statistics, " \
                     "and Solid Cable connection observability — all without leaving your app."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/solid_stack_web"
  spec.metadata["changelog_uri"]   = "https://github.com/eclectic-coding/solid_stack_web/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "pagy", ">= 43.0"
  spec.add_dependency "solid_queue", ">= 1.0"
  spec.add_dependency "solid_cache", ">= 1.0"
  spec.add_dependency "solid_cable", ">= 1.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
end
