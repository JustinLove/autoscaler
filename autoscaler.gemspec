# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "autoscaler/version"

Gem::Specification.new do |s|
  s.name        = "autoscaler"
  s.version     = Autoscaler::VERSION
  s.authors     = ["Justin Love", "Fix Peña"]
  s.email       = ["git@JustinLove.name"]
  s.homepage    = "https://github.com/JustinLove/autoscaler"
  s.summary     = %q{Start/stop Sidekiq workers on Heroku}
  s.description = %q{Currently provides a Sidekiq middleware that does 0/1 scaling of Heroku processes}
  s.licenses    = ["MIT"]

  s.rubyforge_project = "autoscaler"

  s.files         = Dir["CHANGELOG.md", "README.md", "lib/**/*", "examples/**/*"]
  s.test_files    = Dir["Guardfile", "spec/**/*.rb"]

  s.require_paths = ["lib"]

  s.required_ruby_version = '~> 2.1'

  s.add_runtime_dependency "sidekiq", '~> 6.0'
  s.add_runtime_dependency "platform-api", '~> 2.0'

  s.add_development_dependency "bundler", '~> 1.0'
  s.add_development_dependency "rspec", '~> 3.0'
  s.add_development_dependency "rspec-its", '~> 1.0'
  s.add_development_dependency "guard-rspec", '~> 4.0'
  s.add_development_dependency "guard-process", '~> 1.0'
end
