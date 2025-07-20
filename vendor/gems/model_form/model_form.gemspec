lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "model_form/version"

Gem::Specification.new do |spec|
  spec.name          = "model_form"
  spec.version       = ModelForm::VERSION
  spec.authors       = ["Timo Göllner", "Dominik Menke"]
  spec.email         = ["tg@digineo.de", "dom@digineo.de"]

  spec.summary       = "Form Model Presenters and Service Objects"
  spec.homepage      = "http://www.digineo.de/"

  # this is an internal gem
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = %w[lib]

  spec.add_dependency "activemodel",          ">= 4.0", "< 8" # AM::Model
  spec.add_dependency "activesupport",        ">= 4.0", "< 8" # concerns, delegates, string inflection
  spec.add_dependency "virtus",               "~> 1.0.5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
