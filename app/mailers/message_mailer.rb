class MessageMailer < ApplicationMailer
  %i[inquiry imessage message_text message_action].tap do |attrs|
    attr_reader(*attrs)
    private(*attrs) # rubocop:disable Style/AccessModifierDeclarations
    helper_method(*attrs)
  end

  helper_method :villa_rent_for_owner_message, :admin_booking_url, :boat_rent_for_owner_message

  expose(:booking)       { inquiry.booking }
  expose(:customer)      { inquiry.customer }
  expose(:villa_inquiry) { inquiry.villa_inquiry }
  expose(:villa)         { villa_inquiry&.villa } # in Tests, villa_inquiry might not exist
  expose(:clearing)      { inquiry.clearing }
  expose(:boat_inquiry)  { inquiry.boat_inquiry }
  expose(:boat)          { boat_inquiry.boat }
  expose(:manager)       { villa.manager }

  def owner_booking_message(message:, inquiry:, to:)
    @imessage = message
    @inquiry  = inquiry

    I18n.with_locale :en do
      mail(
        to:         to,
        subject:    inquiry_subject("message_mailer.owner_booking_message.subject"),
        store_with: message,
      )
    end
  end

  def boat_owner_booking_message(message:, inquiry:, to:)
    @imessage = message
    @inquiry  = inquiry

    I18n.with_locale :en do
      mail(
        to:         to,
        subject:    inquiry_subject("message_mailer.boat_owner_booking_message.subject"),
        store_with: message,
      )
    end
  end

  def note_mail(message:, inquiry:, to:)
    @inquiry = inquiry
    @manager = message.recipient

    # HACK: `{Villa,Boat}Inquiry#notify_contracts` attach a small action to the
    # message text (separated by 0x03 (ETX, end-of-text)), in order to influence
    # the rendered partials.
    #
    # Example: If `@message_action == "cancel"`, `@inquiry.boat_booking` might
    # point to a boat of an owner different to current recipient (`to`). Here,
    # most of the information in the note mail body shall never be included.
    @message_text, @message_action = message.text.to_s.split("\x03", 2)

    mail(
      to:         to,
      subject:    inquiry_subject("message_mailer.note_mail.subject"),
      store_with: message,
    )
  end

  private

  def villa_rent_for_owner_message
    inquiry.villa_inquiry.build_billing.rent.gross
  end

  def boat_rent_for_owner_message
    inquiry.boat_inquiry.build_billing.rent.gross if inquiry.boat_charged?
  end

  def admin_booking_url
    return admin_cancellation_url(inquiry.cancellation) if inquiry.cancelled?

    super booking
  end
end
