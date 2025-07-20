class Clearing
  class Rentable
    include Clearing::CommonTotals
    attr_accessor :clearing_items

    delegate :blank?,
      to: :clearing_items

    def initialize(clearing_items)
      self.clearing_items = clearing_items
    end

    def update_clearing_items(new_clearing_items)
      old_clearing_items = clearing_items.to_a

      new_clearing_items.count.times do |i|
        nci = new_clearing_items[i]

        if (oci = old_clearing_items.find { |ci| ci.category == nci.category })
          oci.attributes        = nci.attributes.except("id", "inquiry_id")
          new_clearing_items[i] = old_clearing_items.delete oci
        end
      end
      self.clearing_items = new_clearing_items

      old_clearing_items
        # Rabatte/Storno nicht entfernen
        .reject { |oci| oci.category.include?("discount") || oci.category.include?("reversal") }
        .each { |oci| oci._destroy = true }

      self.clearing_items += old_clearing_items

      self
    end

    def deposits
      clearing_items.select { |ci| ci.category == "deposit" }
    end

    def discounts
      clearing_items.select { |ci| ci.category.include? "discount" }
    end

    def reversals
      clearing_items.select { |ci| ci.category.include? "reversal" }
    end

    def utilities
      clearing_items - rents - deposits
    end

    def rentable_sym
      to_key
    end
  end
end
