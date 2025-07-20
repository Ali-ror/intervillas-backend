# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'digineo_exposer'

Gem::Specification.new do |spec|
  spec.name          = "digineo_exposer"
  spec.version       = DigineoExposer::VERSION
  spec.authors       = ["Dominik Menke"]
  spec.email         = ["dom@digineo.de"]

  spec.summary       = "Stellt Metaprogramming-Methoden expose und memoize zur Verfügung"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "git.digineo.de"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",            "~> 1.11"
  spec.add_development_dependency "rake",               ">= 10.0"
  spec.add_development_dependency "rspec-core",         "~> 3.4"
  spec.add_development_dependency "rspec-expectations", "~> 3.4"
  spec.add_development_dependency "rspec-mocks",        "~> 3.4"
end
