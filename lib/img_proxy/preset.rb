# NOTE: Changes here require a server restart.

module ImgProxy
  class Preset
    attr_reader :name, :options

    delegate :fetch, :each_with_object,
      to: :options

    def initialize(name, **options)
      @name    = name
      @options = options.freeze
    end

    def to_s
      each_with_object([]) { |(option, args), list|
        opt = case option
        when :fit, :fill then resize(option, **args)
        when :watermark  then watermark(**args)
        when :format     then format(args)
        else raise ArgumentError, "unexpected preset option: #{option}"
        end
        list << opt
      }.join("/")
    end

    private

    # https://docs.imgproxy.net/generating_the_url?id=resize
    def resize(type, w:, h: 0) # rubocop:disable Naming/MethodParameterName
      "resize:#{type}:#{w}:#{h}"
    end

    # Fix response format. Overrides/circumvents "Accept" header detection.
    # https://docs.imgproxy.net/generating_the_url?id=format
    def format(ext)
      "format:#{ext}"
    end

    # https://docs.imgproxy.net/generating_the_url?id=watermark
    def watermark(pos:, opacity:, scale:, x: 0, y: 0) # rubocop:disable Naming/MethodParameterName
      "watermark:#{opacity}:#{pos}:#{x}:#{y}:#{scale}"
    end
  end
end
