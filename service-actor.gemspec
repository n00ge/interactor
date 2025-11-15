# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "service-actor"
  spec.version = "1.0.0"

  spec.author      = "n00ge"
  spec.email       = "n00ge@github.com"
  spec.description = "Simple service objects (actors) with type-safe contracts for Ruby 3.x"
  spec.summary     = "Service objects with contracts for Ruby 3.x"
  spec.homepage    = "https://github.com/n00ge/service-actor"
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
    "bug_tracker_uri" => "https://github.com/n00ge/service-actor/issues",
    "changelog_uri" => "https://github.com/n00ge/service-actor/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/n00ge/service-actor",
    "rubygems_mfa_required" => "true"
  }

  spec.post_install_message = <<~MSG
    service-actor 1.0.0 is a modernized fork of collectiveidea/interactor.
    Special thanks to Collective Idea for the original interactor gem!

    New features:
    - Ruby 3.x compatibility (no OpenStruct)
    - Type-safe contracts with expects/ensures DSL
    - Zero external dependencies

    See https://github.com/n00ge/service-actor for documentation.
  MSG
end
