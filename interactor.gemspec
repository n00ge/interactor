# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "interactor"
  spec.version = "4.0.0"

  spec.author      = "Collective Idea"
  spec.email       = "info@collectiveidea.com"
  spec.description = "Interactor provides a common interface for performing complex user interactions."
  spec.summary     = "Simple interactor implementation"
  spec.homepage    = "https://github.com/collectiveidea/interactor"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir[
    "lib/**/*.rb",
    "MIT-LICENSE",
    "README.md"
  ]
  spec.test_files = Dir["spec/**/*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/collectiveidea/interactor/issues",
    "changelog_uri" => "https://github.com/collectiveidea/interactor/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/collectiveidea/interactor",
    "rubygems_mfa_required" => "true"
  }
end
