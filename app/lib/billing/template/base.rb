module Billing::Template # rubocop:disable Style/ClassAndModuleChildren
  class Base < Struct.new(:billing) # rubocop:disable Style/StructInheritance
    include Texd::Helpers # brings `#escape`
    include Billing::Template::Helpers
    include ActionView::Helpers::NumberHelper

    attr_reader :locale, :number

    delegate :booking, :billables, :charges, :date,
      to: :billing

    delegate :customer, :inquiry,
      to: :booking

    def initialize(*)
      super
      @locale = I18n.default_locale
      @number = booking.number
    end

    def template
      @template ||= "billings/#{self.class.name.demodulize.underscore}"
    end

    def locals
      {
        tpl:       self,
        locale:    locale,
        number:    number,
        date:      date,
        inquiry:   inquiry,
        customer:  customer,
        booking:   booking,
        billing:   billing,
        billables: billables,
        charges:   charges,
      }
    end
  end
end
