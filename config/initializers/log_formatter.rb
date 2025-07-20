if %w[ development test ].include?(Rails.env) && %w[ dominik.digineo.lan ].include?(`hostname -f`.strip)
  class Logger::SimpleColored < Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter

    def call(severity, time, progname, msg)
      prefix_lines make_message(msg), make_prefix(severity, progname)
    end

  private

    def prefix_lines(lines, prefix)
      lines.split("\n").map{|e| e.gsub(/^(?!$)/, prefix) }.join("\n") + "\n"
    end

    def make_prefix(severity, progname)
      [
        format_severity(severity),
        (format_progname(progname) if progname)
      ].compact.join " "
    end

    def format_severity(severity)
      unless Rails.application.config.colorize_logging
        return "#{severity} "
      end

      case severity
      when 'DEBUG'  then sprintf "\033[%smD\033[0m ", "0;34"   # blue
      when 'INFO'   then sprintf "\033[%smI\033[0m ", "1;37"   # bold white
      when 'WARN'   then sprintf "\033[%smW\033[0m ", "1;33"   # bold yellow
      when 'ERROR'  then sprintf "\033[%smE\033[0m ", "1;31"   # bold red
      when 'FATAL'  then sprintf "\033[%smF\033[0m ", "1;7;31" # bold black, red bg
      else               "#{severity} " # none
      end
    end

    def format_progname(progname)
      if Rails.application.config.colorize_logging
        "\033[1;30m#{progname}:\033[0m " # extra space!
      else
        "#{progname}: "
      end
    end

    def make_message(msg)
      msg = msg.inspect unless String === msg
      return msg unless Rails.application.config.colorize_logging
      return msg if msg.index("\033") # don't overwrite existing color

      color = case msg
        when /\AStarted (?:GET|POST|PATCH|PUT|DELETE) "\// then "1;4;32" # bold underline green
        when /\ACompleted 2\d\d/                           then "4;32" # underline green
        when /\ACompleted 3\d\d/                           then "4;33" # underline yellow
        when /\ACompleted 4\d\d/                           then "4;31" # underline red
        when /\ACompleted 5\d\d/                           then "7;31" # black, red bg
      end

      return msg unless color
      sprintf "\033[%sm%s\033[0m\n", color, msg.strip
    end
  end

  Rails.logger.formatter = Logger::SimpleColored.new
end
