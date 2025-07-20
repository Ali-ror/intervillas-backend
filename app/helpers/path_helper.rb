module PathHelper
  def localized_path(symbol, *args)
    send([I18n.locale, symbol, "path"].join("_"), *args)
  end
end
