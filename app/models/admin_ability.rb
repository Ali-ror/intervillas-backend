class AdminAbility
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new(locked_at: Time.current)
    cannot :manage, :all

    case @user.access_level
    when "admin"     then admin_abilities
    when "inquiries" then inquiry_abilities # + {booking,rentable}_abilities
    when "bookings"  then booking_abilities # + rentable_abilities
    when "rentables" then rentable_abilities
    when "none"      then guest_abilities
    end
  end

  def admin_abilities
    can :manage, :all
    cannot %i[destroy], Page, &:route_with_name?
    cannot :destroy, Cancellation
    cannot %i[edit update destroy], Inquiry, &:cancelled?
  end

  def inquiry_abilities
    can :index, Inquiry
    can :read, Inquiry, villa_inquiry: { villa_id: villa_ids }
    can :read, Inquiry, boat_inquiry: { boat_id: boat_ids }

    booking_abilities
  end

  def booking_abilities
    can :index, Booking
    can :read, [Inquiry, Booking], villa_inquiry: { villa_id: villa_ids }
    can :read, [Inquiry, Booking], boat_inquiry:  { boat_id: boat_ids }

    rentable_abilities
  end

  def rentable_abilities
    can_read_own_calendar
    can_grid_and_print_own_bookings
  end

  def guest_abilities
    can :read, Page
  end

  def villa_ids
    @villa_ids ||= @user.villa_ids
  end

  def boat_ids
    @boat_ids ||= @user.boat_ids
  end

  private

  def can_read_own_calendar
    cannot %i[read calendar], Villa
    can    %i[read calendar], Villa, id: villa_ids
    cannot %i[read calendar], Boat
    can    %i[read calendar], Boat, id: boat_ids
  end

  def can_grid_and_print_own_bookings
    cannot %i[index new create update preview edit], Booking
    can    %i[read print grid], Booking, villa_inquiry: { villa_id: villa_ids }
    can    %i[read print grid], Booking, boat_inquiry: { boat_id: boat_ids }
  end
end
