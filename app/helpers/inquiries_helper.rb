module InquiriesHelper
  def reservation_form_tag(villa)
    tag.reservation_form nil,
      ":id" => villa.id,
      "url" => villa_villa_inquiries_path(villa)
  end

  def clearing_table_tag(inquiry)
    clearing = ApplicationController.render(
      partial: "api/clearings/clearing",
      locals:  { clearing: inquiry.clearing, inquiry: inquiry },
      format:  :json,
    )

    tag.clearing_table nil,
      ":clearing"  => clearing,
      ":no-footer" => true
  end
end
