module LocaleDomain
  def self.extract(request)
    # locale from params
    loc = request.params["locale"].presence
    return loc if loc && available_locales.include?(loc)

    # locale from URL
    loc = request.subdomains.first
    return loc if loc && available_locales.include?(loc)

    I18n.default_locale.to_s # auch bei "www."
  end

  def self.available_locales
    @available_locales ||= I18n.available_locales.map(&:to_s)
  end

  Constraint = Struct.new(:locale) do
    def matches?(request)
      locale.to_s == LocaleDomain.extract(request)
    end
  end
end
