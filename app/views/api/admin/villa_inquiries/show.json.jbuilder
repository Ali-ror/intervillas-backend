vi      = villa_inquiry
inquiry = vi.inquiry

json.inquiry do
  json.call inquiry,
    :id,
    :external,
    :created_at,
    :updated_at,
    :booked_at,
    :booking_updated_at,
    :cancelled_at,
    :currency

  json.travel_insurance inquiry.customer.travel_insurance

  json.clearing do
    json.partial! "/api/clearings/clearing", clearing: inquiry.clearing
  end

  json.villa_inquiry do
    json.call vi,
      :inquiry_id,
      :villa_id,
      :villa_name,
      :start_date,
      :end_date,
      :adults,
      :children_under_6,
      :children_under_12,
      :nights,
      :energy_cost_calculation

    travelers = inquiry.travelers.order(
      start_date:     :asc,
      price_category: :asc,
      last_name:      :asc,
      first_name:     :asc,
    )
    json.travelers travelers do |traveler|
      json.call traveler,
        :id,
        :first_name,
        :last_name,
        :price_category,
        :born_on,
        :start_date,
        :end_date
      json.isValid ""
    end

    json.discounts villa_inquiry.discounts do |discount|
      json.call discount,
        :subject,
        :value
      json.start_date discount.period.min
      json.end_date   discount.period.max
    end

    json.public_villa_path villa_path(villa_inquiry.villa)
  end

  if (boat_inquiry = inquiry.boat_inquiry)
    json.boat_inquiry do
      json.inclusive boat_inquiry.inclusive?
      json.call boat_inquiry,
        :inquiry_id,
        :boat_id,
        :start_date,
        :end_date,
        :name,
        :days

      json.discounts boat_inquiry.discounts do |discount|
        json.call discount,
          :subject,
          :value
        json.start_date discount.period.begin
        json.end_date   discount.period.end
      end
    end
  end
end

json.partial! "api/admin/villa_inquiries/villas"
json.inconsistencies localized_inconsistencies(vi.inquiry)
