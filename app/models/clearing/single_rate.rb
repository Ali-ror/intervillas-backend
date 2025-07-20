class Clearing::SingleRate < SimpleDelegator
  attr_reader :normal_price

  def initialize(single_rate_d, normal_price: nil)
    super(single_rate_d)
    @normal_price = normal_price
  end

  def ==(other)
    (self.class === other) &&
      (other.__getobj__ == __getobj__) &&
      (other.normal_price == @normal_price)
  end

  alias eql? ==

  def hash
    __getobj__.hash ^ normal_price.hash
  end
end
