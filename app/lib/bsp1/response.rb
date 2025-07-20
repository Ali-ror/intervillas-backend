class Bsp1::Response
  attr_accessor :attributes

  def initialize(attributes)
    self.attributes = attributes.with_indifferent_access
  end

  def error?
    status == "ERROR"
  end

  def redirect?
    status == "REDIRECT"
  end

  def redirect_url
    attributes[:redirecturl]
  end

  def status
    attributes[:status]
  end

  def customermessage
    attributes[:customermessage]
  end
end