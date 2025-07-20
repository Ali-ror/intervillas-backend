module SchemaOrgHelper
  # setter
  def schema_scope(context = nil, val = nil)
    @schemas ||= Hash.new false

    if context.nil? && val.nil?
      @schemas
    elsif val.nil?
      @schemas[context]
    else
      @schemas[context] = val
      true
    end
  end

  # getter
  def schema_org(context, &content)
    if (v = schema_scope(context))
      content_tag :div, itemscope: "itemscope", itemtype: "http://schema.org/#{v}", &content
    else
      capture(&content)
    end
  end
end
