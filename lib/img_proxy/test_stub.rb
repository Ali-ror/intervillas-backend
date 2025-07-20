# NOTE: Changes here require a server restart.

module ImgProxy
  class TestStub < Middleware
    def initialize(*)
      super

      @fixture = Rails.root.join("spec/fixtures/file.jpg").read(mode: "rb")
    end

    # We can't share a volume on CI, so local:// paths won't work.
    # For now, we simply stub access to the instance.
    #
    # To check if this works locally, run `STUB_IMGPROXY=1 rspec`.
    def cache(_, file_name, _, _, _)
      headers = {
        "Content-Type"           => "image/jpeg",
        "Vary"                   => "Accept",
        "Content-Disposition"    => %(inline; filename="#{file_name}"),
        "X-Content-Type-Options" => "nosniff",
        "Cache-Control"          => "max-age=#{TTL.to_i}, public",
        "Expires"                => TTL.from_now.httpdate,
      }

      [200, headers, [@fixture]]
    end
  end
end
