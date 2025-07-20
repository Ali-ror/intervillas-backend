class AdminMailer < ApplicationMailer
  # @param [Booking, Blocking] booking_or_blocking
  def clash(booking_or_blocking, ical_blocking)
    @booking  = booking_or_blocking
    @blocking = ical_blocking
    @clash    = find_clash

    date = @clash.begin.strftime("%m/%Y")
    mail \
      to:      "info@intervillas-florida.com",
      from:    "noreply@intervillas-florida.com",
      subject: "Kollision Buchung #{@booking.number} mit iCal-Kalender (#{date})"
  end

  def payout_reminder(inquiry_ids)
    @inquiries = VillaInquiry.where(inquiry_id: inquiry_ids).includes(villa: :owner)

    mail \
      to:      "info@intervillas-florida.com",
      from:    "noreply@intervillas-florida.com",
      subject: "Erinnerung an vorzeitige Auszahlung"
  end

  private

  def find_clash
    a, b = if @booking.start_date <= @blocking.start_date
      [@booking, @blocking]
    else
      [@blocking, @booking]
    end

    if a.end_date > b.end_date
      (b.start_date .. b.end_date)
    else
      (b.start_date .. a.end_date)
    end
  end
end
