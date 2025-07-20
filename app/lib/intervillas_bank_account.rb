module IntervillasBankAccount
  class Account
    ATTRIBUTES = %i[
      address
      swift
      owner
      iban
      account
      bank_identifier
      clearing
      routing
      scope
    ].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(**options)
      ATTRIBUTES.each do |a|
        val = [*options[a]].map(&:presence).compact
        instance_variable_set "@#{a}", val
      end
    end

    def each_detail
      (ATTRIBUTES - %i[address scope]).each do |a|
        next if (val = public_send(a)).empty?

        yield a, val
      end
    end

    def to_html
      parts.join("<br>\n")
    end

    def to_s
      parts.join("\n")
    end

    def t(name)
      if name.to_s == "scope"
        I18n.t scope[0], scope: "intervillas_bank_account.scope"
      else
        I18n.t name, scope: "intervillas_bank_account"
      end
    end

    private

    def parts
      %w[iban swift account bank_identifier clearing routing].each_with_object([
        address&.join(", "),
        owner&.join(", "),
      ]) do |f, parts|
        if (var = instance_variable_get("@#{f}")&.first.presence)
          parts << format("%s: %s", t(f), var)
        end
      end.compact
    end
  end

  ACCOUNTS_GMBH = [
    Account.new(
      scope:           "eu",
      address:         ["Sparkasse Hochrhein", "Kaiserstrasse 17, 79761 Waldshut-Tiengen"],
      owner:           ["Intervilla GmbH", "Rebenstrasse 34, CH-8309 Nürensdorf"],
      iban:            "DE59 6845 2290 0077 0436 93",
      swift:           "SKHRDE6W",
      account:         "77043693",
      bank_identifier: "68452290",
    ),
    Account.new(
      scope:    "ch",
      address:  ["Zürcher Kantonalbank", "Bahnhofstr. 10, CH-8302 Kloten"],
      owner:    ["Intervilla GmbH", "Rebenstrasse 34, CH-8309 Nürensdorf"],
      iban:     "CH83 0070 0130 0074 5647 6",
      swift:    "ZKBKCHZZ80A",
      account:  "1300-7456.476",
      clearing: "700",
    ),
    Account.new(
      scope:    "usd",
      address:  ["Zürcher Kantonalbank", "Bahnhofstr. 10, CH-8302 Kloten"],
      owner:    ["Intervilla GmbH", "Rebenstrasse 34, CH-8309 Nürensdorf"],
      iban:     "CH19 0070 0130 0077 5318 7",
      swift:    "ZKBKCHZZ80A",
      account:  "1300-7753.187",
      clearing: "700",
    ),
  ].freeze

  ACCOUNTS_CORP = [
    Account.new(
      scope:   "any",
      address: ["JPMorgan Chase Bank, N.A.", "383 Madison Avenue", "New York, NY 10179", "USA"],
      owner:   ["Intervilla Corp.", "4929 SW 26th Ave", "Cape Coral, FL 33914", "USA"],
      account: "653 668 221",
      routing: "267 084 131",
      swift:   "CHASUS33XXX",
    ),
  ].freeze

  class << self
    def accounts(type: nil)
      case type
      when :corp
        ACCOUNTS_CORP
      when :gmbh
        ACCOUNTS_GMBH
      else
        if DateTime.current >= Rails.configuration.x.corporate_switch_date
          ACCOUNTS_CORP
        else
          ACCOUNTS_GMBH
        end
      end
    end

    delegate :each,
      to: :accounts

    def for_currency(currency, type: nil)
      candidates = accounts(type:)

      if currency == Currency::USD
        candidates.select { _1.scope.include?("any") || _1.scope.include?("usd") }
      else
        candidates.reject { _1.scope.include?("usd") }
      end
    end
  end
end
