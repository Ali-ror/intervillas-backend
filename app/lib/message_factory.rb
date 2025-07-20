#
# Generiert für verschiedene Zwecke ein oder mehrere Message-Instanzen
#
module MessageFactory
  class << self
    def for(entry_point)
      factory = case entry_point
      when ::Inquiry, ::BoatInquiry, ::VillaInquiry
        MessageFactory::Inquiry
      when ::Booking
        MessageFactory::Booking
      when ::Billing
        MessageFactory::Billing
      when ::Cancellation
        MessageFactory::Cancellation
      else
        raise ArgumentError, "no factory known for #{entry_point.class}"
      end
      factory.new(entry_point)
    end

    def build(entry_point, type)
      self.for(entry_point).build(type)
    end

    def find_or_build(entry_point, type)
      factory = self.for(entry_point)
      factory.find(type) || factory.build(type)
    end
  end

  class Base < SimpleDelegator
    def build(type)
      type = type.to_s
      messages.build recipient: recipient(type), template: template(type)
    end

    def find(type)
      type = type.to_s
      messages.find_by template: template(type)
    end

    # soll den Empfänger für ein bestimmtes Template (User oder Customer) liefern
    def recipient(_type)
      raise NotImplementedError, "must be implemented in sub class"
    end

    # soll den Namen eines Mailing-Templates liefern
    def template(_type)
      raise NotImplementedError, "must be implemented in sub class"
    end
  end

  class Inquiry < Base
    def build_many(type)
      raise ArgumentError, "only 'owner' and 'manager' supported" unless %w[owner manager].include?(type)

      filter_valid_messages [
        build(type),
        (build("boat_#{type}") if with_optional_boat?),
      ]
    end

    def recipient(type)
      case type
      when "owner", "owner_booking_message"           then villa.owner
      when "boat_owner", "boat_owner_booking_message" then boat.owner
      when "manager"                                  then villa.manager
      when "boat_manager"                             then boat.manager
      else __getobj__.customer
      end
    end

    def template(type)
      case type
      when "owner"                   then "owner_booking_message"
      when "boat_owner"              then "boat_owner_booking_message"
      when "manager", "boat_manager" then "note_mail"
      else type
      end
    end

    private

    def with_optional_boat?
      with_boat? && boat_optional?
    end

    def filter_valid_messages(messages)
      messages.select { |m|
        m&.recipient.present? && !m.recipient.email_addresses.empty?
      }
    end
  end

  class Booking < Inquiry
    def initialize(booking)
      super booking.inquiry
    end
  end

  class Cancellation < Inquiry
    delegate :messages, to: :inquiry

    def build_many(*)
      filter_valid_messages [
        build("owner"),
        build("manager"),
        (build("boat_owner")   if with_optional_boat?),
        (build("boat_manager") if with_optional_boat?),
      ]
    end

    def template(*)
      "note_mail"
    end
  end

  class Billing < Base
    delegate :messages, to: :booking

    def recipient(type)
      case type
      when "tenant" then customer
      when "villa"  then villa.owner
      when "boat"   then boat.owner
      end
    end

    def template(type)
      case type # rubocop:disable Style/HashLikeCase
      when "tenant" then "tenant_billing"
      when "villa"  then "villa_owner_billing"
      when "boat"   then "boat_owner_billing"
      end
    end
  end
end
