class BlockingForm < ModelForm
  from_model :blocking

  attribute :villa_id, Integer
  attribute :boat_id, Integer
  attribute :start_date, Date

  attribute :end_date, Date
  validates :end_date, presence: true,
    ends_after_start: true,
    availability: true

  attribute :comment, String
  validates :comment, presence: true

  def rentable
    if villa_id.present?
      Villa.find villa_id
    elsif boat_id.present?
      Boat.find boat_id
    else
      nil
    end
  end

  def destroy_button(view)
    return unless persisted?
    view.link_to "Termin freigeben", [:admin, blocking],
      class: 'btn btn-danger',
      method: :delete
  end

end
