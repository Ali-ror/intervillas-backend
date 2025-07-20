module SalutationHelper
  def salute(salutable)
    salutable.salutation.strip.tap {|s|
      s << "," unless s.ends_with?(",")
    }
  end
end
