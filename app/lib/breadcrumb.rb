class Breadcrumb

  def initialize(view)
    @view = view
    @links = [
      @view.link_to("Home", @view.root_path)
    ]
  end

  def add(link)
    @links << link
    nil
  end

  def render(active)
    @view.content_tag :ol, class: 'breadcrumb' do
      [
        @links.map do |link|
          @view.content_tag :li, link
        end.join.html_safe,
        @view.content_tag(:li, active, class: 'active')
      ].join.html_safe
    end
  end


end
