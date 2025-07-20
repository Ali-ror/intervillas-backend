ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "logger" # backport https://github.com/rails/rails/pull/49372

require "bundler/setup" # Set up gems listed in the Gemfile.
