class Api::ClearingsController < ApplicationController
  attr_accessor :clearing
  helper_method :clearing

  expose(:inquiry) do
    if params[:inquiry_id]
      Inquiry.find(params[:inquiry_id])
    elsif params[:token]
      Inquiry.find_by(token: params[:token])
    end
  end

  rescue_from ClearingItem::InvalidPrice do |e|
    render plain: e.message, status: :unprocessable_entity
  end

  def show
    render_price_table(valid_at: inquiry.created_at, currency: inquiry.currency) do
      self.clearing = inquiry.clearing.update(villa_params, boat_params, inquiry)
    end
  end

  def new
    return show      if params[:inquiry_id].present?
    return just_boat if params[:token].present? && params[:villa].blank?

    @currency = params[:currency]
    render_price_table(valid_at: Time.current, currency: @currency) do
      self.clearing = Clearing.build(villa_params, external: params[:external] == "true")
    end
  end

  private

  def render_price_table(valid_at:, currency: nil, &block)
    villa_params.prices_valid_at = valid_at
    return head :unprocessable_entity unless villa_params.valid?

    if currency
      Currency.with(currency, &block)
    else
      yield
    end
    render
  end

  def just_boat
    self.clearing = inquiry.clearing.update(nil, boat_params, inquiry)

    render
  end

  def boat_params
    return nil if params[:boat].blank?

    ::Clearing::BoatParams.new.tap do |bp|
      bp.boat       = boat
      bp.start_date = permitted_params[:boat][:start_date]
      bp.end_date   = permitted_params[:boat][:end_date]
    end
  end

  memoize(:villa_params, private: true) do
    vp = Clearing::VillaParams.new

    if (villa_params = params[:villa].presence)
      vp.start_date        = villa_params[:start_date] if villa_params.key?(:start_date)
      vp.end_date          = villa_params[:end_date] if villa_params.key?(:end_date)
      vp.adults            = villa_params[:adults] if villa_params.key?(:adults)
      vp.children_under_12 = villa_params[:children_under_12] if villa_params.key?(:children_under_12)
      vp.children_under_6  = villa_params[:children_under_6] if villa_params.key?(:children_under_6)
      vp.travelers         = travelers if permitted_params[:villa][:travelers]
    end

    vp.villa = villa
    vp
  end

  def permitted_params
    @permitted_params ||= params.permit(
      villa: [:villa_id, { travelers: %i[born_on start_date end_date price_category] }],
      boat:  %i[boat_id start_date end_date],
    )
  end

  def travelers
    permitted_params[:villa][:travelers].to_h.map { |_, t| Traveler.new(t) }
  end

  def villa
    ::Villa.find(params[:villa][:villa_id])
  end

  def boat
    ::Boat.find(params[:boat][:boat_id])
  end
end
