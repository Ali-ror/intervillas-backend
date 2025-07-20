class Ability
  include CanCan::Ability

  def initialize(user)
    cannot :manage, :all

    can [:read, :price, :gallery, :geocodes, :search, :gap], Villa
    can [:create, :update], Inquiry
    can [:create], Booking
  end
end
