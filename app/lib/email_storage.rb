module EmailStorage
  extend ActiveSupport::Concern

  included do
    ApplicationMailer.register_observer ::EmailStorage::Observer
  end

  def mail(*args, store_with: nil, **kwargs, &block)
    super(*args, **kwargs, &block).tap { |mail_message|
      break unless store_with&.respond_to?(:store_eml)

      mail_message.instance_variable_set(:@_store_with, store_with)
    }
  end

  class Observer
    mattr_accessor :known, instance_writer: false, instance_reader: false do
      Set.new
    end

    def self.delivered_email(mail)
      store_with = mail.instance_variable_get(:@_store_with)
      store_with.store_eml(mail) if store_with.present?
    end
  end
end
