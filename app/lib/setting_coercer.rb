module SettingCoercer
  def self.dump(coercable)
    coercable.to_yaml         # this is a single document, so we remove:
      .gsub(/\A--- /, "")     # begin-of-document and
      .gsub(/\n...\n\z/, "")  # end-of-document marker
  end

  def self.load(string)
    return if string.blank?

    YAML.safe_load string, permitted_classes: [::BigDecimal]
  end

  class Base
    attr_reader :name, :default

    def initialize(name, default)
      @name    = name
      @default = default
    end

    def get
      # `s = Setting.find(name)` breaks in tests (db_cleaner sometimes runs too early)
      s = Setting.find_by(key: name) || Setting.create!(key: name, value: default)
      yield s if block_given?
      s.value
    end

    def set(val)
      get { _1.update_attribute :value, coerce!(val) } # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def coerce!(val)
      raise NotImplementedError, "must be implemented in subclass"
    end
  end

  # Warning: DO NOT USE THIS, but create another subclass of
  # SettingCoercer::Base implementing the details for the type you want.
  # This is just a class intended for development and may break at any
  # given moment.
  class Generic < Base
    attr_reader :type

    def initialize(name, default, type)
      @type = type
      super name, default
    end

    private

    def coerce!(val)
      # no coercion needed, val matches type
      return val if val.is_a?(type)

      # works well for Integer(), Float(), Rational(), less so for Array()
      return Kernel.send(type.name, val) if Kernel.respond_to?(type.name)

      raise TypeError, "unsupported coercion: don't know how to coerce #{val} from #{val.class} to #{type}"
    end
  end

  class BigDecimal < Base
    def initialize(name, default)
      super name, default.to_d
    end

    private

    def coerce!(val)
      val.to_d
    end
  end
end
