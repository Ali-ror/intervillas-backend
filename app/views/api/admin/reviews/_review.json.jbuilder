json.call review,
  :id,
  :rating,
  :name,
  :city,
  :text,
  :published_at

if text = review.text.presence
  json.preview RenderKramdown.new(text).to_html
end

json.booking do
  json.number     review.inquiry.number
  json.start_date review.inquiry.start_date
  json.end_date   review.inquiry.end_date
  json.url        edit_admin_inquiry_path(review.inquiry)
end

json.url api_admin_review_path(review)
