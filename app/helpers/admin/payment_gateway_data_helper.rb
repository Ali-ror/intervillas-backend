module Admin::PaymentGatewayDataHelper
  def render_payment_gateway_tree(data)
    PaymentGatewayDataRenderer.new(data, self).render
  end

  PaymentGatewayDataRenderer = Struct.new(:data, :view_context) do
    delegate :tag, :t, :l, :number_to_currency,
      to: :view_context

    def render
      render_recursive(data)
    end

    def h(*args)
      # view_context.h ist private
      view_context.send :h, *args
    end

    def render_recursive(data) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
      case data
      when Hash
        tag.ul do
          data.keys.sort { |a, b|
            if a == "id"
              -3
            elsif b == "id"
              3
            elsif a.end_with?("_time")
              -2
            elsif b.end_with?("_time")
              2
            else
              a <=> b
            end
          }.map { |key|
            val = data[key]

            tag.li do
              h("#{key}: ") + case key
              when "links"
                render_links(val)
              when "amount"
                render_amount(val)
              when "currency", "transaction_fee"
                render_currency(val)
              when /_time\z/
                I18n.l(DateTime.parse(val), format: "%d.%m.%Y, %H:%M:%S Uhr")
              else
                render_recursive(val)
              end
            end
          }.join.html_safe
        end

      when Array
        tag.ol do
          data.map { |value|
            tag.li do
              render_recursive(value)
            end
          }.join.html_safe
        end

      when NilClass, ""
        tag.em("n/a", class: "text-muted")

      else
        tag.code(data.to_s, class: "small")
      end
    end

    def render_links(links)
      tag.ul do
        links.map { |link|
          tag.li do
            tag.code(link["method"]) + h(" #{link['rel']}: ") + tag.code(link["href"])
          end
        }.join.html_safe # rubocop:disable Rails/OutputSafety
      end
    end

    def render_amount(amount)
      currency = amount["currency"]
      total    = tag.li(h("total: ") + number_to_currency(amount["total"].to_d, unit: currency))

      tag.ol do
        %w[
          subtotal
          shipping
          tax
          fee
          handling_fee
          shipping_discount
          insurance
          gift_wrap
        ].map { |f|
          next unless (details = amount["details"].presence)
          next unless (val     = details[f].presence)

          tag.li { h("#{f}: ") + number_to_currency(val, unit: currency) }
        }.compact.join.html_safe + total
      end
    end

    def render_currency(currency)
      return currency if currency.is_a?(String)

      # TODO: wo kommt currency hier her? -> display_price benutzen
      number_to_currency currency["value"].to_d, unit: currency["currency"]
    end
  end
end
