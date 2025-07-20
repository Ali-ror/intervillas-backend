class ChromeLogging
  attr_reader :logs

  def initialize(logs)
    @logs = logs
  end

  def drain
    logs.available_types.each do |type|
      messages = logs.get(type).map { |log|
        msg = format_message(log.level, log.message)
        msg if msg && !ignore?(msg)
      }.compact

      yield type, messages unless messages.empty?
    end
  end

  private

  LOGGING_COLORIZATION = {
    "DEBUG"   => "0;34", # blue
    "INFO"    => "1;37", # bold white
    "WARNING" => "1;33", # bold yellow
    "SEVERE"  => "1;31", # bold red
  }.freeze
  private_constant :LOGGING_COLORIZATION

  def format_message(level, msg)
    return if msg.include? "vue-devtools"

    colorize level, unwrap(msg)
  end

  def unwrap(msg)
    m = msg.match(%r{^(https?://[^\s]+\s+\d+:\d+)\s*(.*)}m)
    return msg unless m

    # trim webpack url prefix
    src = m[1].gsub(%r{^http://127\.0\.0\.1:\d+/packs-test/}, "[webpack] ")

    # some characters are encoded (like "<")
    msg = m[2].gsub(/(?:\\u(\h{4}))/) { Regexp.last_match(1).hex.chr Encoding::UTF_8 }

    if msg =~ /\A"(.*)"\z/ || msg =~ /\A{(.*)}\z/
      # some messages don't survive the transport from
      # chrome → chromedriver → selenium → capybara
      msg = JSON.parse(msg) rescue msg
    end

    "(#{src})  #{msg}"
  end

  def colorize(level, msg)
    if (c = LOGGING_COLORIZATION[level])
      "\033[#{c}m#{level}\033[0m  #{msg}"
    else
      "#{level}  #{msg}"
    end
  end

  IGNORE_MESSAGES = [
    /\[vue-router\] <router-link>'s (tag|event) prop is deprecated and has been removed in Vue Router 4. Use the v-slot API/,
    /Error: no WebGL support detected/,
  ].freeze
  private_constant :IGNORE_MESSAGES

  def ignore?(msg)
    IGNORE_MESSAGES.any? { |pat| msg.match(pat) }
  end
end

RSpec.configure do |config|
  config.after(type: :feature) do |example|
    if Capybara.current_driver != :firefox && (b = page.driver.browser) && b.respond_to?(:logs)
      # Always drain logs and then decide whether to print them (not the other way around).
      # Otherwise the logs accumulate in Chrome/Chromedriver and will all be printed on the
      # next (legitimate) error. many messages, such confusion.
      ChromeLogging.new(b.logs).drain do |type, messages|
        # TODO: collect logs and present them at the end (interweaved with the RSpec failure list).
        #
        # This should be possible, since `example.metadata` is just a Hash and RSpec formatters
        # provide an `extra_detail_formatter`. We "just" need to figure out how to access that
        # from here (or better from `config.after(:suite)`).
        if ENV["CHROME_SHOW_LOGS"] == "1" || ENV["CI"] == "1" || example.exception.present?
          warn "", "=== #{type} logs for '#{example.description}':", messages
        end
      end
    end
  end
end
