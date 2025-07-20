json.array! collection do |review|
  json.(review, :id, :rating, :villa_name, :name, :city, :published_on)
  json.villa_path villa_path review.villa
  json.text format_review review

  if review.villa.present?
    teaser = VillaTeaserDecorator.new(Currency::USD, review.villa)
    json.main_image teaser.main_image_url
  end
end
