module ClickHelper
  def click_on_until_content(locator, content:)
    click_on_until locator do
      page.has_content? content, wait: 0.5
    end
  end

  def click_on_until(locator)
    until yield
      @a          ||= 0
      break if (@a += 1) > 10

      if @a > 1
        STDERR.puts "retry(#{@a}) click_on #{locator}"
        sleep 0.1
        break if yield
      end
      find(locator, match: :first).click
    end
    @a = 0
  end

  def wait_until
    until yield
      @a          ||= 0
      break if (@a += 1) > 10

      next unless @a > 1

      STDERR.puts "retry(#{@a})"
      sleep 0.1
      break if yield
    end
    @a = 0
  end
end

RSpec.configure do |config|
  config.include ClickHelper, type: :feature
end
