module Admin::SalesHelper
  def to_currency_hash(cvs)
    cvs.each_with_object({}) { |cv, a| a[cv.currency] = cv.value }
  end
end
