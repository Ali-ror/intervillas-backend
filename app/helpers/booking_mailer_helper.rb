module BookingMailerHelper
  # see also LayoutHelper#confirmation_subsection
  def confirmation_subsection(title, &block)
    render layout: "booking_mailer/confirmation_subsection", locals: { title: title }, &block
  end
end
