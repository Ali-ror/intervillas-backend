class Api::BoatInquiriesController < ApiController
  expose(:inquiry)    { Inquiry.find_by!(token: params[:token]) }
  expose(:start_date) { inquiry.start_date + 1.day }
  expose(:end_date)   { inquiry.end_date - 1.day }

  expose :available_boats do
    boats = inquiry.villa.optional_boats
      .includes(:owner, :translations)
      .to_a

    # Boot des Eigentümers nach vorne sortieren
    if (owner_boat = boats.find { |boat| boat.owner == inquiry.villa.owner })
      boats.unshift boats.delete(owner_boat)
    end

    boats
  end
end
