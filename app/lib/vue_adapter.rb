#
# VueAdapter allows a unified JSON export interface for Vue frontend
# components. Simply create a subclass and implement the `*_for_vue`
# methods.
#
# This currently needs a bit more glue code to be actually useful, and
# only represents a work-in-progess. Known implementors are:
#
# - Admin::DomainController::DomainJSON,
# - Admin::SnippetsController::SnippetJSON, and
# - Api::Admin::VillasController::VillaJSON
#
# The surrounding controller classes are very similar in nature and
# might become subject to cleanup as well.
#
class VueAdapter < SimpleDelegator
  class Context
    include Rails.application.routes.url_helpers
    delegate :default_url_options,
      to: "Rails.application.config.action_mailer"

    def initialize(env)
      return if %w[ test development ].include?(env)
      warn "VueAdapter::Context is not intended for production usage!"
    end
  end

  attr_reader :context

  def initialize(obj, context: nil)
    @context = context || Context.new(Rails.env)
    super(obj)
  end

  def as_json(*, include_collections: true, **)
    {
      attributes:  attributes_for_vue,
      collections: (collections_for_vue if include_collections),
      endpoint:    endpoint_for_vue,
    }.compact
  end

  private

  # Returns a Hash<Symbol,*> with attributes editable in the frontend.
  #
  # Avoid creating deeply nested structures for things the user should
  # not modify, and instead reference them by ID. Then add a corresponding
  # entry to `collections_for_vue`.
  def attributes_for_vue
    raise NotImplementedError, "must be implemented in subclass"
  end

  # Returns a Hash<Symbol,Array<*>> with objects selectable (but not editable)
  # in the frontend.
  #
  # Usually (but not necessarily), `attributes_for_vue[:foo_ids]` is an
  # array of IDs which correspond to elements in `collections_for_vue[:foo]`.
  def collections_for_vue
    raise NotImplementedError, "must be implemented in subclass"
  end

  # Should return a Hash (`{ url: URL, method: HTTPVerb }`) describing
  # the API endpoint for Vue.
  #
  # Usually, HTTPVerb is "PATCH" or "POST", depending on `self.new_record?`.
  # The path helpers are available through `self.context`.
  def endpoint_for_vue
    raise NotImplementedError, "must be implemented in subclass"
  end
end
