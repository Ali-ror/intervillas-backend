# Basiert auf Rails::MailersController aus railties
class Admin::PreviewsController < ApplicationController
  include Admin::ControllerExtensions

  expose(:email) {
    mailer_class.send(mailer_action, inquiry: inquiry, to: customer)
  }

  # Vorschau Bestätigungsmail
  def show
    authorize! :preview, booking

    @part = find_preferred_part(request.format, Mime[:html], Mime[:text])
    render layout: false
  end

  private

  memoize :booking do
    Booking.find params[:id]
  end

  delegate :inquiry, :customer, to: :booking, allow_nil: true

  def mailer_class
    params[:mailer_class].constantize
  end

  def mailer_action
    params[:mailer_action]
  end

  def find_preferred_part(*formats)
    formats.each do |format|
      if part = email.find_first_mime_type(format)
        return part
      end
    end

    if formats.any?{ |f| email.mime_type == f }
      email
    end
  end
end
