module MyBookingPal
  module Async
    class FeesTaxesPusher < Base
      def perform(id, reset_progress = false)
        track_progress(id, "fees_taxes", reset: reset_progress) {
          product = Product.find_by(id: id)
          return unless product&.foreign_id?

          MyBookingPal.post("/taxfee", data: {
            productId: product.foreign_id,
            fees:      [
              {
                altId:      "house_deposit",
                entityType: "MANDATORY",
                feeType:    "DEPOSIT",
                name:       "Deposit",
                unit:       "PER_STAY",
                value:      product.villa.villa_price(Currency::USD).deposit.value,
                valueType:  "FLAT",
              }, {
                altId:      "cleaning",
                entityType: "MANDATORY",
                feeType:    "GENERAL",
                name:       "Cleaning",
                unit:       "PER_STAY",
                value:      product.villa.villa_price(Currency::USD).cleaning.value,
                valueType:  "FLAT",
              },
            ],
            taxes:     [
              {
                altId: "tourist",
                name:  "Tourist tax",
                type:  "SalesTaxIncluded",
                value: Taxable.find_taxes(:tourist).values.sum(0) * 100,
              }, {
                altId: "sales_2019",
                name:  "Sales tax",
                type:  "SalesTaxIncluded",
                value: Taxable.find_taxes(:sales_2019).values.sum(0) * 100,
              },
            ],
          })
        }
      end
    end
  end
end
