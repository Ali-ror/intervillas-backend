module OpenGraphHelper
  class OpenGraph
    attr_reader :view

    def initialize(view)
      @fields, @view = {}, view
    end

    def add(tag, content)
      @fields[tag] = content
      self
    end

    def method_missing(name, *args, &b)
      return add(name, args[0]) if args.size == 1
      super
    end

    def render
      @fields.map {|tag, content|
        @view.tag :meta, property: "og:#{tag}", content: content
      }.join.html_safe
    end
  end

  def opengraph_data(&block)
    @opengraph = yield OpenGraph.new(self)
  end

  def render_opengraph_metadata
    return unless OpenGraph === @opengraph
    @opengraph.render
  end
end
