# Rails.backtrace_cleaner.remove_silencers!

# RSpec.configure do |config|
#   config.filter_gems_from_backtrace(
#     "actionpack",
#     "actionview",
#     "actionmailer",
#     "activemodel",
#     "activerecord",
#     "activesupport",
#     "bootsnap",
#     "bundler",
#     "capybara",
#     "factory_bot",
#     "globalize",
#     "graticule",
#     "haml",
#     "inherited_resources",
#     "modware",
#     "mongo",
#     "omniauth",
#     "rack",
#     "rack-test",
#     "railties",
#     "request_store",
#     "responders",
#     "rest-client",
#     "rspec-core",
#     "rspec-expectations",
#     "rspec-support",
#     "schema_monkey",
#     "schema_plus_core",
#     "sidekiq",
#     "vcr",
#     "warden",
#     "webmock"
#   )
#
#   # [
#   # /(?-mix:(?-mix:\/lib\/rspec\/(core|mocks|expectations|support|matchers|rails|autorun)(\.rb|\/))|rubygems\/core_ext\/kernel_require\.rb)|(?-mix:\/lib\d*\/ruby\/)|(?-mix:bin\/)|(?-mix:exe\/rspec)/,
#   # /\/lib\/rspec\/its/,
#   # /vendor\//,
#   # / lib\/rspec\/rails /
#   # ]
#   config.backtrace_exclusion_patterns -= [%r{vendor/}]
# end
