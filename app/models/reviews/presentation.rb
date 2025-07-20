module Reviews::Presentation

  def villa_name
    villa.name
  end

  def published_on
    published_at&.to_date
  end
end
