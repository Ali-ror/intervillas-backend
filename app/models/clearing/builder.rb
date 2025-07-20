class Clearing
  class Builder
    attr_accessor :params, :clearing_items, :inquiry, :external

    def initialize(params, inquiry: nil, external: inquiry&.external)
      self.params         = params
      self.inquiry        = inquiry
      self.external       = external
      self.clearing_items = []
    end

    def save_to(inquiry)
      clearing_items.each do |ci|
        ci.inquiry = inquiry
        ci.save!
      end
      inquiry.clearing_items.reload
    end
  end
end
