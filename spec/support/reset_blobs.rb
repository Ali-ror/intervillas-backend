# Clears tmp/data-test/{blobs,variants}
#
# Can't do a `rm -rf tmp/data-test/{blobs,variants}` directly, because
# these directories are mounted in imgproxy, so we clear the children.
RSpec.configure do |config|
  config.before(:suite) do
    %w[blobs variants].each do |name|
      dir = Rails.root.join("tmp/data-test", name)
      dir.children.each(&:rmtree) if dir.exist?
    end
  end
end
