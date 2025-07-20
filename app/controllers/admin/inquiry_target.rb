#
# Wenn /admin/{inquiries,bookings,cancellations}/:id{,/edit} abgerufen
# wird, soll automatisch auf die richtige Seite umgeleitet werden, also:
#
# - Anfragen/Offerten zu /admin/inquiries/...
# - Buchungen         zu /admin/bookings/...
# - Storniereungen    zu /admin/cancellations/...
#
# Wird vom Admin::InquiriesCtrl eingemischt und steht via Vererbung
# im Admin::Bookings- und Admin::CancellationsCtrl zur Verfügung.
#
module Admin::InquiryTarget
  extend ActiveSupport::Concern

  TARGET_MAPPING = {
    "inquiries"     => ::Inquiry,
    "bookings"      => ::Booking,
    "cancellations" => ::Cancellation,
  }.freeze

  included do
    before_action :redirect_to_actual, only: %i[edit show]

    expose :redirect_target do
      inquiry.terminus || inquiry
    end
  end

  private

  def redirect_to_actual
    klass = TARGET_MAPPING.fetch(controller_name, false)
    return unless klass # falscher Controller

    # wir sind schon am Ziel
    return if redirect_target.is_a?(klass)

    case action_name
    when "edit"
      redirect_to [:edit, :admin, redirect_target]
    when "show"
      redirect_to [:admin, redirect_target]
    end
    # alles andere erlauben
  end
end
