# Preview all emails at http://localhost:3000/rails/mailers/admin
class AdminPreview < ActionMailer::Preview
  def clash
    AdminMailer.clash(
      Booking.last,
      Blocking.where.not(calendar: nil).last
    )
  end
end
