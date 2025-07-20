module Admin::BillingsHelper

  def month_select_collection
    (1..12).map {|i|
      [ I18n.t("date.month_names")[i], i ]
    }
  end

  def year_select_collection
    (2011 .. (Time.current.year + 2))
  end

end
