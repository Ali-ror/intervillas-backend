module HelperMethods
  PRICE_TABLE_SELECTOR = "#price_table:not(.refreshing)".freeze

  def within_price_table(&block)
    within PRICE_TABLE_SELECTOR, &block
  end

  def expect_admin_price_table_rent_entry(subject, count, nights, base_rate, total)
    within_price_table do
      expected = [subject, count, nights, base_rate, total].compact.join(" ")
      expect(page).to have_text expected
    end
  end

  def expect_price_table_entry(subject, total, currency = "€")
    within_price_table do
      expected = [subject, currency, total].compact.join(" ")
      expect(page).to have_text expected
    end
  end

  def within_price_row(category, nested_within: nil, &block)
    selector = [PRICE_TABLE_SELECTOR, nested_within, "tr"]
      .map(&:presence)
      .compact
      .join(" ")

    within selector, text: category, match: :first, &block
  end

  BlankValue = Class.new(StandardError)

  def expect_price_row_value(category, value, wait: Capybara.default_max_wait_time, within: nil)
    raise BlankValue if value.blank?

    within_price_row(category, nested_within: within) do
      expect(page).to have_content value, wait: wait
    end
  end

  # Eine Zeile in der Preistabelle mit Kategorie und Datumswerten finden
  # Wird für Preistabellen mit unterschiedlichen Reisezeiträumen der Teilnehmer gebraucht
  #
  # @param [String] key Achtung!, hier muss die Kategorie mit Komma getrennt übergeben werden (2 Erwachsene, Grundpreis), da der Tooltip für das Matching benutzt wird
  # @param [Symbol,String] alt
  # @param [Array<Date>] dates [start_date, end_date]
  # @param [Integer] wait Capybara.max_wait_time
  def expect_price_row_value_lookup_with_dates(key, alt = nil, dates:, wait: Capybara.default_max_wait_time)
    formatted_dates = [
      dates[0].strftime("%d.%m.%Y"),
      dates[1].strftime("%d.%m.%Y"),
    ].join " bis "

    title = "#{formatted_dates}, #{key}"
    within %(#{PRICE_TABLE_SELECTOR} tr[title$="#{title}"]) do
      expect(page).to have_content curr_values.lookup_value(key.gsub(",", ""), alt), wait: wait
    end
  end

  def expect_price_breakdown_lookup(label, key = label, alt = nil, within: nil)
    _, value = curr_values.lookup(key, alt)
    expect_price_row_value(label, value, within: within)
  end

  def expect_price_row_value_lookup(key, alt = nil)
    name, value = curr_values.lookup(key, alt)
    expect_price_row_value(name, value)
  end

  def expect_price_row_field_lookup(key, alt = nil)
    name, opts = curr_values.lookup_field(key, alt)
    expect_price_row_field(name, **opts)
  end

  # similar to something like
  #
  #     expect {
  #       change_to_normal(category)
  #     }.to change(price_row_value).from(from).to(to)
  #
  # without the fuzz needed to create a chaining matcher
  def expect_normal_price_changing_total(category, *dates, from:, to:, normal:)
    formatted_dates = [
      dates[0].strftime("%d.%m.%Y"),
      dates[1].strftime("%d.%m.%Y"),
    ].join " bis "

    title = "Villa: #{formatted_dates}, #{category}"

    within %(#{PRICE_TABLE_SELECTOR} tr[title="#{title}"]) do
      expect(page).to have_content from

      click_on "Normalpreis vorhanden"
      click_on "Normalpreis von #{normal}"

      expect(page).to have_content to
    end
  end

  def expect_price_row_field(category, with:)
    within_price_row category do
      expect(page).to have_field with: format("%g", with)
    end
  end

  def expect_high_season_rents
    within_price_table do
      expect_price_row_value_lookup("14 Nächte Grundpreis")
      expect_price_row_value_lookup("14 Nächte + Hochsaison")
      expect_price_row_value_lookup("Mietpreis", :high_season)
      expect_price_row_value_lookup("Mietkosten", :high_season)
      expect_price_row_value_lookup("Mietkosten inkl. Kaution", :high_season)
    end
  end

  def expect_billing_row(statement, gross)
    within "tr", text: statement, match: :first do
      expect(page).to have_content gross
    end
  end

  def expect_saved
    expect(page).to have_flash "success", "Buchungsdaten erfolgreich gespeichert"
  end

  def expect_inquiry_created
    expect(page).to have_no_content "SPEICHERE", wait: 3
    expect(page).to have_no_content "Speichern fehlgeschlagen"
    expect(page).to have_css "h1", text: /IV-E?\d+/
  end

  def expect_occupancies_loaded
    expect(page).to have_no_content "Termine werden geladen..."
  end

  def add_names_to_travelers
    within_fieldset "Reisende" do
      find_all("tbody tr").each.with_index do |tr, i|
        within tr do
          fill_in "Nachname", with: "Reisender #{i}"
          fill_in "Vorname", with: "Namenloser #{i}"
        end
      end
    end
  end

  def add_boat(admin_display_name, start_date, end_date)
    click_on "Boot hinzufügen"
    expect(page).to have_no_content "Hole Belegungsdaten"
    ui_select admin_display_name, from: "Boot"

    await_page_component_refresh ".admin-boat-selector .form-control.disabled"
    within "form .form-group", text: "Boot" do
      date_range_picker.select_dates \
        start_date,
        end_date
    end
  end

  def create_billing
    click_on "Abrechnung"
    fill_in "Beginn", with: 2
    fill_in "Ende", with: 2
    click_on "Abrechnung speichern"
    click_on "Abrechnungen"
  end

  def add_discount(human_rentable, amount, note: "Spezialrabatt")
    add_position "Rabatt", human_rentable, amount, note: note
  end

  def add_reversal(human_rentable, amount, note: "Spezialrabatt")
    add_position "Stornogebühr", human_rentable, amount, note: note
  end

  def add_position(category, human_rentable, amount, note: nil)
    click_on "Posten hinzufügen"
    click_on "#{human_rentable}-#{category}"
    fill_in_clearing_item "#{human_rentable}-#{category}", with: amount, note: note
  end

  def fill_in_clearing_item(category, with:, note: nil)
    within "#price_table tr", text: category do
      find("input").fill_in with: with
      if note.present?
        accept_prompt with: note do
          find("i[title='Notiz eingeben']").click
        end
      end
    end
  end

  # wartet darauf, dass ein Element eine CSS-Klasse nicht mehr hat
  def await_page_component_refresh(component_selector)
    expect(page).to have_no_css component_selector
    yield if block_given?
  end

  def fake_payment(provider, booking)
    case provider
    when :bsp1
      fake_bsp1_payment booking
    when :paypal
      fake_paypal_payment booking
    else
      raise "Unknown provider: #{provider}"
    end
  end

  def fake_bsp1_payment(booking)
    expect(page).to have_content "Restzahlung fällig"

    expect(page).to have_content "Zahlen mit Kreditkarte"
    expect(page).to have_css ".inputIframe > iframe"

    # Wenn hier die Formularfelder ausgefüllt werden würden, würde ein Request gegen die BS PAYONE
    # API losgetreten werden. In deren Doku steht allerdings, dass der "mode=test" nicht für
    # automatisierte Tests gedacht ist, daher wird hier der Callback direkt ausgeführt:
    page.execute_script <<-JAVASCRIPT
      (window["remainder-cccCallback"] || window["downpayment-cccCallback"])({
        status:           "VALID",
        pseudocardpan:    "9410010000183255710",
        cardtype:         "V",
        truncatedcardpan: "411111XXXXXX1111",
        cardexpiredate:   "2212"
      });
    JAVASCRIPT

    expect(page).to have_content I18n.t("js.bsp1_form.success")

    # Antworten von BSP1 treffen nebenläufig ein
    inquiry = booking.inquiry
    calc    = PaypalHelper::ChargeCalculator.new :bsp1,
      currency:              booking.currency,
      prices_include_cc_fee: booking.prices_include_cc_fee

    net_payment = PaymentDeadlines.from_inquiry(inquiry).due_sum
    amount      = calc.add(net_payment).gross

    bpp = booking.bsp1_payment_processes.first
    api = Faraday.new(url: "http://localhost:5051")
    api.post("/api/bsp1/transaction_status", bsp1_appointed(amount, bpp.txid, inquiry.number))
    api.post("/api/bsp1/transaction_status", bsp1_paid(amount, bpp.txid, inquiry.number))

    net_payment
  end

  def bsp1_req(txid, txaction, transaction_status = nil, **values)
    values[:txid]               = txid
    values[:txaction]           = txaction
    values[:transaction_status] = transaction_status if transaction_status.present?
    values[:txtime]             = Time.current.to_i
    values[:key]                = "6593449aea0d44bd85c755bec9d2484c"
    values[:mode]               = "test"
    values
  end

  def bsp1_appointed(amount, txid, booking_number)
    bsp1_req(txid, :appointed, :completed, price: amount, balance: amount, receivable: amount, reference: "#{booking_number}-t1")
    # {
    #   "key"                => "6593449aea0d44bd85c755bec9d2484c",
    #   "txaction"           => "appointed",
    #   "portalid"           => "2031373",
    #   "aid"                => "43559",
    #   "clearingtype"       => "cc",
    #   "notify_version"     => "7.6",
    #   "txtime"             => "1557485881",
    #   "currency"           => Currency::EUR,
    #   "userid"             => "164822991",
    #   "accessname"         => "",
    #   "accesscode"         => "",
    #   "param"              => "",
    #   "mode"               => "test",
    #   "price"              => "689.15",
    #   "txid"               => "332555821",
    #   "reference"          => "mvQRToqRCig1ptRq",
    #   "sequencenumber"     => "0",
    #   "company"            => "",
    #   "firstname"          => "",
    #   "lastname"           => "Lindgren",
    #   "street"             => "",
    #   "zip"                => "",
    #   "city"               => "",
    #   "email"              => "",
    #   "country"            => "KH",
    #   "cardexpiredate"     => "2212",
    #   "cardtype"           => "V",
    #   "cardpan"            => "411111xxxxxx1111",
    #   "transaction_status" => "completed",
    #   "balance"            => "689.15",
    #   "receivable"         => "689.15"
    # }
  end

  def bsp1_paid(amount, txid, booking_number)
    bsp1_req(txid, :paid, price: amount, balance: 0, receivable: amount, reference: "#{booking_number}-t1")
  end

  def build_sdk_payment(state, ppch)
    PayPal::SDK::REST::Payment.new(
      id:           "PAYID-MARHMWI5W724192UX5042640",
      state:        state,
      create_time:  "2018-06-13T01:14:45Z",
      update_time:  state == "completed" ? "2018-06-13T01:14:45Z" : nil,
      links:        [{
        rel:  "approval_url",
        href: "https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-FOO",
      }],
      transactions: [{
        related_resources: [{
          sale: {
            amount: {
              total:    ppch.gross,
              details:  {
                subtotal:     ppch.net,
                handling_fee: ppch.charge,
              },
              currency: Currency::EUR,
            },
          },
        }],
      }],
    )
  end

  def fake_paypal_payment(reservation)
    inquiry = reservation.inquiry
    calc    = PaypalHelper::ChargeCalculator.new :paypal,
      currency:              inquiry.currency,
      prices_include_cc_fee: inquiry.prices_include_cc_fee
    ppch    = calc.add PaymentDeadlines.from_inquiry(inquiry).due_sum

    # Nur prüfen, ob der Link/Button exisitiert. Ein Klick würde zur Paypal-Sandbox
    # navigieren, die (mit unserer VCR-Kassette) schon mehrfach 400er und 500er
    # produziert hat.
    expect(page).to have_button "#{display_price(ppch.gross.round(2))} bezahlen"

    # Stattdessen simulieren wir die Interaktion mit Paypal
    approved = build_sdk_payment("approved", ppch)
    inquiry.create_or_update_paypal_payment!(approved)

    # Rückkehr von Paypal
    # visit api_paypal_payment_complete_path(inquiry_token: inquiry.token)
    visit payments_path(reservation.inquiry.token)

    # Hier wird normalerweise eine Flash-Nachricht angezeigt

    completed = build_sdk_payment "completed", ppch
    inquiry.create_or_update_paypal_payment!(completed)
  end

  def switch_to_usd
    visit "/"
    click_on "Preise in US$ anzeigen"
  end

  def navigate_to_inquiry_create
    visit admin_root_path

    click_on "Buchungen"
    click_on "Anfragen/Offerten"
    click_on "Angebot erstellen"

    expect(page).to have_no_content "Bitte warten, Daten werden geladen"
  end

  def enter_house_data(curr, _curr_values)
    ui_select villa.name, from: "Villa"

    date_range_picker.select_dates \
      villa_inquiry_params[:start_date],
      villa_inquiry_params[:end_date]

    2.times { add_traveler "Namenloser", "Reisender" }
    expect_price_row_value "Grundpreis", "2.240,00" # Hier ist noch EUR eingestellt

    within "fieldset", text: "Kundendaten" do
      select curr, from: "Währung"

      select customer_params[:locale], from: "Sprache"
      select customer_params[:title], from: "Anrede"
      fill_in "Vorname", with: customer_params[:first_name]
      fill_in "Nachname", with: customer_params[:last_name]
      fill_in "E-Mail-Adresse", with: customer_params[:email]
      fill_in "Telefon", with: customer_params[:phone]
    end
    expect_price_row_value_lookup("14 Nächte Grundpreis")

    click_on "Speichern"
    expect_inquiry_created

    expect(Customer.last.phone).to eq customer_params[:phone]

    expect_price_row_value_lookup("14 Nächte Grundpreis")
  end

  def add_traveler(first_name, last_name, start_date = nil, end_date = nil)
    within_fieldset "Reisende" do
      click_on "Reisenden hinzufügen"

      within find_all("tbody tr").last do
        fill_in "Vorname", with: first_name
        fill_in "Nachname", with: last_name
        select I18n.t(:adults, scope: "admin.inquiries.clearing.villa"), from: "Preiskategorie"

        return unless start_date

        # Geburtstag ausfüllen
        birthday = Traveler.born_on_for_traveler_category(:adults, start_date)
        within "td:nth-child(4)" do
          find("input").click
          date_range_picker.select_dates birthday
        end

        return unless end_date

        # An- und Abreise ausfüllen
        within "td:nth-child(5)" do
          date_range_picker.select_dates start_date, end_date
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include HelperMethods, type: :feature
end
