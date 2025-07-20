# Preview all emails at http://localhost:3000/rails/mailers/message_mailer
class MessageMailerPreview < ActionMailer::Preview
  def owner_booking_message
    message = Message.where(template: "owner_booking_message").last
    MessageMailer.owner_booking_message \
      message: message,
      inquiry: message.inquiry,
      to:      message.recipient.emails.first
  end

  [nil, "book", "dates", "cancel"].each do |action|
    define_method ["note_mail", action].compact.join("_") do
      message = Message.where(template: "note_mail").last.tap { |m|
        m.text = m.message_text + "\x03#{action}" if action
      }

      MessageMailer.note_mail \
        message: message,
        inquiry: message.inquiry,
        to:      message.recipient.emails.first
    end
  end
end
