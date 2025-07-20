require "img_proxy"

stub_imgproxy = ENV.fetch("STUB_IMGPROXY", "0") == "1" || (Rails.env.test? && ENV.fetch("CI", "0") == "1")
middleware    = stub_imgproxy ? ImgProxy::TestStub : ImgProxy::Middleware
backend       = ENV.fetch("IMGPROXY_BACKEND_URL", "http://localhost:2206")

Rails.application.config.middleware.insert_after Rails::Rack::Logger, middleware,
  backend: backend,
  source:  "local://data/#{Rails.env}"
