class PageTemplateFuncs
  # %foo% or %bar(snafu)%, not %parens()%
  RE = /%(?<name>\w+)(?:\((?<arg>[^)]+)\))?%/.freeze
  private_constant :RE

  def self.apply_to(view_context, content)
    funcs = new(view_context)

    content.gsub(RE) {
      name, arg = Regexp.last_match.values_at(:name, :arg)

      if funcs.respond_to?(name)
        funcs.send(name, arg)
      else
        funcs.unknown(name)
      end
    }
  end

  def initialize(view_context)
    @ctx = view_context
  end

  # %intervillas_bank_account%
  def intervillas_bank_account(*)
    @ctx.render partial: "pages/intervillas_bank_accounts"
  end

  # %intervillas_bank_account% legacy
  alias intervillas_bank_accounts intervillas_bank_account

  def intervillas_tax_info(*)
    @ctx.render partial: "pages/intervillas_tax_info"
  end

  # %intervillas_address(type)%
  def intervillas_address(type)
    @ctx.render partial: "pages/intervillas_address", locals: { type: type }
  end

  JURISDICTION = {
    [:de, true]  => [
      "Der Vertrag untersteht ausschliesslich US-amerikanischem Recht.",
      "Der Gerichtsstand ist Fort Myers, Flodia, Vereinigte Staaten.",
    ],
    [:en, true]  => [
      "This contract is subject to US law exclusively.",
      "The place of jurisdiction is Fort Myers, FL, USA.",
    ],
    [:de, false] => [
      "Der Vertrag untersteht ausschliesslich schweizerischem Recht.",
      "Der Gerichtsstand ist Zürich, Schweiz.",
    ],
    [:en, false] => [
      "This contract is subject to Swiss law exclusively.",
      "The place of jurisdiction is Zurich, Switzerland.",
    ],
  }.transform_values { _1.join(" ") }.freeze
  private_constant :JURISDICTION

  def intervillas_jurisdiction(*)
    JURISDICTION.fetch([I18n.locale, @ctx.intervilla_corp?]) {
      unknown("intervillas_jurisdiction") # unreachable
    }
  end

  # %carousel(id)%
  def carousel(id)
    if (image = Media::Image.find_by(id: id)).present?
      @ctx.media_path(image, preset: :carousel)
    else
      unknown("carousel(#{id})")
    end
  end

  def unknown(name)
    @ctx.tag.em "(unknown template function: #{name})", class: "text-danger"
  end
end
