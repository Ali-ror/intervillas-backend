require "rails_helper"

RSpec.describe Bsp1::PlainKeyValue do
  context "when condition" do
    it "decodes hash arguments from plain text body" do
      response_env = OpenStruct.new(body: "foo=bar\nbar=baz")
      listener     = double(on_complete: nil)
      expect(listener).to receive(:on_complete).and_yield(response_env)
      app          = double(call: listener)
      request_env  = OpenStruct.new(body: {})
      Bsp1::PlainKeyValue.new(app).call(request_env)
      expect(response_env.body).to include("foo" => "bar")
      expect(response_env.body).to include("bar" => "baz")
    end
  end
end