module AdminInquiriesHelper
  def inquiry_or_booking(inquiry)
    inquiry.cancellation.presence || inquiry.booking.presence || inquiry
  end

  def inquiry_number(inquiry)
    n = inquiry.number
    inquiry.cancelled? ? content_tag(:s, n) : n
  end
end
