# Simple helper to allow conditionally activating breakpoints, in lieu
# of proper IDE integration (*coff* vscode *coff*).
#
# This is particularly useful if the code-to-debug is deeply nested,
# or called from multiple, unrelated sites.
#
# Usage:
#
#     # in spec
#     with_debugger { expect(subject.foo) to bar }
#
#     # in code
#     def foo
#       debugger if $debug_on
#     end
#
# Nesting and conditionals are supported:
#
#     with_debugger {
#       do_something
#       with_debugger(false) { do_something } # temporarily disabled
#       do_something
#     }
module DebugHelper
  # rubocop:disable Style/GlobalVars

  def with_debugger(enable = true)
    was_on    = $debug_on
    $debug_on = enable
    yield
  ensure
    $debug_on = was_on
  end

  # rubocop:enable Style/GlobalVars
end

RSpec.configure do |config|
  config.include DebugHelper
  config.extend DebugHelper
end
