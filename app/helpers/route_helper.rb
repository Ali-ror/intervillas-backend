module RouteHelper
  attr_writer :title, :meta_description

  def title
    title = route.html_title if route
    title.presence || @title
  end

  def route
    return @route if defined?(@route)

    if params[:action] == 'show' && defined?(resource) && resource.respond_to?(:route)
      @route ||= resource.route
    end

    @route ||= Route.where(path: request.path.gsub!(/^\//, "")).first
    @route
  end

  def h1
    route.h1 if route
  end

  def meta_description
    return route.meta_description if route
    @meta_description
  end
end
