require "capybara/rails"
require "capybara/rspec"
require "capybara/email/rspec"

#
# See .env.test for a description of the ENV variables used here!
#

CHROME_DEVTOOLS = ENV.fetch("CHROME_DEVTOOLS", "")

CHROME_EXTENSIONS = [
  *ENV.fetch("CHROME_EXTENSIONS", "").split(","),
  ENV.fetch("VUE_DEVTOOLS", nil),
  "/home/tg/src/external/vue-devtools/packages/shell-chrome",
  Rails.root.join("tmp/vuejs-devtools"),
].uniq.select { |path|
  # check if path and path/manifest.json (i.e. if pointer to unpacked extension)
  path.present? && File.directory?(path) && File.file?(File.join(path, "manifest.json"))
}.freeze

DEFAULT_CHROME_OPTIONS = [
  ("headless" if ENV["HEADLESS"] != "0" && CHROME_DEVTOOLS == ""),
  ("no-sandbox" if Process.uid == 0),
  ("auto-open-devtools-for-tabs" if CHROME_DEVTOOLS != ""),
  "disable-gpu",           # disable GPU accelleration
  "disable-3d-apis",       # disable WebGL
  "mute-audio",            # disable sound
  "window-size=1440,900",  # medium-sized laptop screen
  "disable-dev-shm-usage", # http://crbug.com/715363 might cause invalid session ids
  *CHROME_EXTENSIONS.map { "load-extension=#{_1}" },
].compact.freeze

DEFAULT_DOWNLOAD_DIR = Rails.root.join("tmp/test-downloads").tap(&:mkpath).to_s

def devtools_options
  # camel-case, mixed with kebab-case, and JSON-in-JSON, devtools have it all
  {
    "currentDockState"        => (:undocked if CHROME_DEVTOOLS == "undocked"),
    "panel-selectedTab"       => :network,
    "message-level-filters"   => {
      verbose: false,
      info:    true,
      warning: false,
      error:   true,
    },
    "help.show-release-note"  => false,
    "disable-locale-info-bar" => true,
  }.compact.to_h { |k, v|
    ["devtools.preferences.#{k}", v.to_json]
  }
end

def chrome_options(args: [])
  Selenium::WebDriver::Options.chrome(
    binary:        ENV.fetch("CHROME_BINARY", nil),
    args:          [
      *DEFAULT_CHROME_OPTIONS,
      *args,
    ].compact.freeze,
    logging_prefs: {
      browser: "ALL",
    }.freeze,
    prefs:         devtools_options.merge(
      "autofill.profile_enabled"   => false, # disable "Save Address" prompts
      "download.default_directory" => DEFAULT_DOWNLOAD_DIR,
      "savefile.default_directory" => DEFAULT_DOWNLOAD_DIR,
    ).freeze,
  )
end

def register_chrome_driver(in_driver_name = nil, args: [])
  driver_name = ["chrome", in_driver_name].compact.join("_")

  Capybara.register_driver(driver_name.to_sym) do |app|
    Capybara::Selenium::Driver.new app,
      browser: :chrome,
      options: chrome_options(args:)
  end
end

register_chrome_driver

Capybara.configure do |config|
  # Chrome (Headless) benutzen
  config.server_port           = 5051
  config.app_host              = "http://localhost:5051"
  config.default_driver        = :chrome
  config.javascript_driver     = :chrome
  config.automatic_label_click = true
  config.raise_server_errors   = ENV["RAISE_SERVER_ERRORS"] != "0"
  config.match                 = :prefer_exact
  config.default_normalize_ws  = true
end

module EphemeralSession
  # An ephemeral session is like a normal session created by #using_session,
  # except that it is automatically closed after the block returns.
  #
  # This has the advantage of free'ing resources allocated by the connected
  # browser. Plain #using_session keeps the browser open until the end of
  # the suite.
  #
  # @param _name ignored, but can be used for documentation on the call-site
  # @yield block is called in a new Capybara session
  # @return returns result of block
  def using_ephemeral_session(_name)
    using_session(SecureRandom.uuid) do |session, _|
      yield
    ensure
      session.quit
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::DSL, type: :feature
  config.include EphemeralSession, type: :feature

  config.after type: :feature do |example|
    do_screenshot = ENV["CI"] == "1" || ENV["CAPYBARA_SCREENSHOT_ON_FAILURE"] == "1"
    do_debug      = ENV["PRY_ON_ERR"] == "1"

    if example.exception.present?
      save_screenshot if do_screenshot # rubocop:disable Lint/Debugger
      debugger        if do_debug      # rubocop:disable Lint/Debugger
    end
  end
end
