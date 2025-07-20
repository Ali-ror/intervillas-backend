class MessageForm < ModelForm
  from_model :message

  delegate :email_addresses, :template, :recipient, :inquiry,
    to: :message

  attribute :text, String
end
