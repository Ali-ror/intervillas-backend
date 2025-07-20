module UiSelectHelper
  # Like Capybara's select, but for UiSelect combo/select boxes.
  #
  # @param [String] value Value to be selected.
  # @param [String] from Name (label) for the VueSelect input field
  def ui_select(value, from:)
    # sleep 0.2 if slowdown?

    return ui_multi_select(value, from: from) if value.is_a? Array

    fill_in from, with: value, wait: 5
    find(".vs__dropdown-option--highlight").click
  end

  # gedacht für <ui-select multiple />
  # @param [Array<string>] value Liste von auszuwählenden Optionen.
  #   Bereits ausgewählte Elemente, die nicht in der Liste enthalten sind werden
  #   abgewählt.
  def ui_multi_select(value, from:)
    input  = find(:fillable_field, from)
    to_add = value.to_set
    to_del = Set.new
    input.find_xpath("..").each do |parent|
      parent.find_css(".vs__selected").each do |selected|
        text = selected.all_text.strip
        to_del << text unless to_add.include? text
        to_add.delete text
      end
    end
    to_del.each { click_on "Deselect #{_1}" }
    to_add.each do |text|
      input.fill_in with: text
      input.send_keys :enter
    end
  end

  # expect(page).to have_ui_select expected
  # expect(page).to have_ui_select expected, selected: "..."
  def have_ui_select(expected, **rest)
    Matcher.new(expected, **rest)
  end

  class Matcher
    NOT_GIVEN = Object.new.freeze
    private_constant :NOT_GIVEN

    attr_reader :expected, :selected

    def initialize(expected, selected: NOT_GIVEN)
      @expected = expected
      @selected = selected
    end

    def matches?(actual)
      input = actual.find(:fillable_field, expected)
      input.find_xpath('./preceding-sibling::span[@class="vs__selected"]', text: selected) if with_selection?

      true
    rescue Capybara::ElementNotFound
      false
    end

    def failure_message
      msg  = format("expected to find UiSelect labelled %p", expected)
      msg << format(" and selected value %p", selected) if with_selection?
      msg << ", but found nothing"
    end

    def failure_message_when_negated
      msg  = format("expected not to find UiSelect labelled %p", expected)
      msg << format(" and selected value %p", selected) if with_selection?
      msg << ", but found something"
    end

    private

    def with_selection?
      selected != NOT_GIVEN
    end
  end
end

RSpec.configure do |config|
  config.include UiSelectHelper
end
