module MyBookingPal
  module Reservation
    class Payload # rubocop:disable Metrics/ClassLength
      # DSL to simplify reservation payload handling.
      concerning :DSL do
        class_methods do
          # See https://developerstesting.channelconnector.com/documentation\
          # #/rest/models/structures/new-reservation-notification-object
          #
          # @param [String] source
          #   JSON property name with source casing. Underscore inflection is used to
          #   to produce instance getter and setter, unless a different `name` was
          #   giben.
          # @param [Symbol, #call] converter
          #   Value coercion: a Symbol is sent to the JSON value, a Proc is called
          #   with the JSON value. Note: The block argument takes precedence.
          #   By default, the JSON value is passed unchanged.
          # @param [Symbol, String] name
          #   Attribute name, defaults to `source.to_s.underscore`
          # @yieldreturn
          #   When present, the block overrides the `converter` argument.
          def property(source, converter = :itself, name: source.to_s.underscore, &block)
            raise ArgumentError, "property #{source} already declared" if converters.key?(source)

            conv = if block_given?
              block
            elsif converter.is_a?(Symbol)
              ->(v) { v&.send(converter) }
            elsif converter.respond_to?(:call)
              converter
            else
              raise ArgumentError, "invalid converter for property '#{source}'"
            end

            converters[source] = [name, conv]

            attr_accessor name
          end

          def struct(source, *fields, name: source.to_s.underscore, &converter)
            # define private (sub) struct
            struct = Struct.new(*fields, keyword_init: true)
            struct.define_singleton_method :call, &converter
            cname  = name.to_s.classify.singularize
            const_set cname, struct
            private_constant cname

            # use it a property
            property(source, struct, name:)
          end

          def converters
            @converters ||= {}
          end
        end

        def initialize(raw_data)
          data = raw_data || {}
          todo = data.keys.to_set

          self.class.converters.each do |source, (name, convert)|
            value = convert.call data[source]
            send "#{name}=", value
            todo.delete source
          end

          @raw         = data
          @unique_data = data.slice(*todo)
        end

        def as_json(*)
          @raw
        end

        def instance_variables
          super - %i[@raw] # hide @raw from pretty printers
        end
      end

      concerning :Props do
        included do
          # TODO: The payload contains a unique key/value pair to verify the
          # authenticity of the request.
          attr_reader :unique_data

          property "reservationId", :to_i
          property "productId", :to_i
          property "supplierId", :to_i
          property "channelName"
          property "confirmationId"

          # enum:
          #
          # - "Cancelled":   Reservation was cancelled
          # - "Confirmed":   Reservation processed successfully to the PMS
          # - "FullyPaid":   Reservation processed successfully to the PMS
          #                  (Channel is MOR)
          # - "Provisional": Reservation currently in progress
          # - "Exception":   Previously confirmed or fully paid reservation that
          #                  the HMC no longer has matching closed dates for
          # - "Failed":      Reservation was not successfully processed to the PMS
          #                  or PMS did not provide confirmation
          property "newState", :downcase, name: :status

          struct "customerName", :first_name, :last_name, name: :customer do |val|
            return new unless val

            full_name             = val.to_s
            first_name, last_name = if full_name.include?(",")
              full_name.split(",", 2).map(&:strip).reverse
            else
              full_name.split(/\s+/, 2)
            end

            new(first_name:, last_name:)
          end

          property "fromDate", :to_date, name: :start_date
          property "toDate",   :to_date, name: :end_date

          property "adult", :to_i, name: :adults
          property "child", :to_i, name: :children

          property "address", :presence
          property "city",    :presence
          property "zip",     :presence, name: :postal_code
          property "country", :presence
          property "state",   :presence
          property "email",   :presence
          property "phone",   :presence
          property "notes",   :presence

          # enum: MASTER_CARD, VISA, AMERICAN_EXPRESS, DINERS_CLUB, DISCOVER
          property "creditCardType",            :presence
          property "creditCardNumber",          :presence
          property "creditCardExpirationMonth", :presence
          property "creditCardExpirationYear",  :presence
          property "creditCardCid",             :presence

          property "total", :to_d

          struct "fees", :id, :name, :value do |values|
            (values || []).map { |v|
              new(
                id:    v.fetch("id", nil), # cleaning, house_deposit
                name:  v.fetch("name"),
                value: v.fetch("value").to_d,
              )
            }
          end

          struct "taxes", :id, :name, :value do |values|
            (values || []).map { |v|
              new(
                id:    v.fetch("id", nil), # tourist, sales_2019
                name:  v.fetch("name"),
                value: v.fetch("value").to_d,
              )
            }
          end

          struct "commission", :channel, :bookingpal do |val|
            return new unless val

            new(
              channel:    val.fetch("channelCommission", 0).to_d,
              bookingpal: val.fetch("commission", 0).to_d,
            )
          end

          # @param [BigDecimal] original Rate originally sent to MyBookingPal
          # @param [BigDecimal] net_rate Net rate, to be payed out by MyBookingPal (origin - commissions)
          # @param [BigDecimal] published  Price shown to customer (origin + excluded taxes (?))
          struct "rate", :original, :net_rate, :published do |val|
            return new unless val

            new(
              original:  (val["originalRackRate"] || 0).to_d,
              net_rate:  (val["netRate"] || 0).to_d,
              published: (val["newPublishedRackRate"] || 0).to_d,
            )
          end
        end
      end

      # TODO: removeme after properly creating inquiries (instead of blockings)
      # from MyBookingPal reservations.
      def comment_for_inquiry
        "#{channel_name} via BookingPal ##{reservation_id}"
      end

      def to_customer_params
        {
          **name,
          phone:,
          email:,
          locale:      "en",
          address:,
          postal_code:,
          city:        [city, state].compact_blank.presence,
          country:,
        }
      end

      def to_traveler_params
        {
          "adults"            => adults,
          "children_under_12" => children,
        }.flat_map { |price_category, num|
          num.times.map { { price_category:, **dates, **name } }
        }
      end

      def to_clearing_item_params(villa)
        [
          utility_clearing_item(villa, id: "house_deposit", category: "deposit"),
          utility_clearing_item(villa, id: "cleaning", category: "cleaning"),
          base_rate_clearing_item(villa),
          commission_clearing_item,
        ]
      end

      def rent
        total - (cleaning + deposit + total_commission)
      end

      def deposit
        fees.find { _1.id == "house_deposit" }&.value || 0
      end

      def cleaning
        fees.find { _1.id == "cleaning" }&.value || 0
      end

      def dates
        { start_date:, end_date: }
      end

      def name
        {
          first_name: customer.first_name || "unknown",
          last_name:  customer.last_name  || "unknown",
        }
      end

      def total_commission
        %i[bookingpal channel].sum(0.to_d) { |val|
          commission&.send(val) || 0
        }
      end

      def utility_clearing_item(villa, id:, category:)
        fee = fees.find { _1.id == id }

        {
          villa_id:     villa.id,
          amount:       1,
          category:,
          price:        fee&.value || 0,
          normal_price: fee&.value || 0,
        }
      end

      def base_rate_clearing_item(villa)
        num_people     = adults + children # no distinction here
        length_of_stay = (end_date - start_date).to_i
        tax_rate       = 1.115
        actual_rate    = ((rate.net_rate * tax_rate) - total_commission) / length_of_stay
        base_rate      = actual_rate.round(2)

        {
          **dates,
          villa_id:       villa.id,
          amount:         1,
          category:       "base_rate_booking_pal",
          price:          base_rate,
          normal_price:   base_rate,
          minimum_people: num_people,
        }
      end

      def commission_clearing_item
        {
          villa_id:     nil, # [sic]
          amount:       1,
          category:     "handling",
          price:        total_commission,
          normal_price: total_commission,
          note:         comment_for_inquiry,
        }
      end
    end
  end
end
