class ManagerBookingView < SimpleDelegator
  def self.human_attribute_name(*args)
    Booking.human_attribute_name(*args)
  end

  attr_reader :index_path

  delegate :nights, to: :villa_inquiry

  def initialize(obj, index_path)
    super(obj)
    @index_path = index_path
  end

  def human_attribute_name(*args)
    __getobj__.class.human_attribute_name(*args)
  end

  def boat_start_date
    boat_inquiry.start_date
  end

  def boat_end_date
    boat_inquiry.end_date
  end

  def note
    messages.find_by(template: "manager").try :text
  end

  def inquiry
    Inquiry === __getobj__ ? self : super
  end

  def cancelled?
    Booking === __getobj__ ? false : super
  end

  def adults
    Inquiry === __getobj__ ? villa_inquiry.adults : super
  end

  def children_under_12
    Inquiry === __getobj__ ? villa_inquiry.children_under_12 : super
  end

  def children_under_6
    Inquiry === __getobj__ ? villa_inquiry.children_under_6 : super
  end

  def booked?
    Inquiry === __getobj__ ? false : super
  end

  def booked_on
    Inquiry === __getobj__ ? nil : super
  end

  def created_at
    Inquiry === __getobj__ ? super : inquiry.created_at
  end
end
