module Bsp1PaymentHelper
  def bsp1_params(**in_params)
    Bsp1::Request.hashed_params(**in_params)
  end
end