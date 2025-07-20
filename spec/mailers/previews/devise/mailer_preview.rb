class Devise::MailerPreview < ActionMailer::Preview

  def reset_password_instructions
    user = User.first
    Devise::Mailer.reset_password_instructions(user, "token")
  end

end
