require "virtus"
require "model_form/version"

class ModelForm
  include ActiveModel::Model
  include Virtus.model(nullify_blank: true)

  def init_virtual
    vattrs = attributes.keys.map(&:to_s) - model.attributes.keys.map(&:to_s)

    vattrs.each do |vattr|
      next unless model.respond_to?(vattr)

      send "#{vattr}=", model.send(vattr)
    end
  end

  module DestroyableMethods
    extend ActiveSupport::Concern

    included do
      attr_accessor :_destroy
    end

    def marked_for_destruction?
      _destroy == "1"
    end

    def mark_for_destruction!
      self._destroy = "1"
    end

    def valid?
      marked_for_destruction? || super
    end

    def save
      if marked_for_destruction?
        model.destroy if persisted?
      else
        model.attributes = attributes
        model.save
      end
    end
  end

  module NonDestroyableMethods
    def marked_for_destruction?
      false
    end

    def save
      model.attributes = attributes
      model.save
    end
  end

  def self.from_model(model_sym, destroyable: false)
    attr_accessor model_sym
    alias_method :model, model_sym

    delegate :id, :to_param, :persisted?, :new_record?,
      to:        model_sym,
      allow_nil: true

    # from_XXX factory-methode
    # lädt werte aus dem model
    define_singleton_method "from_#{model_sym}" do |model_instance|
      attributes = model_instance.attributes.reject { |_, value|
        value.nil?
      }

      new(attributes).tap do |form|
        form.send "#{model_sym}=", model_instance
        form.init_virtual
      end
    end

    # wird u.a. zum generieren der routen gebraucht
    define_singleton_method :model_name do
      model_sym.to_s.classify.constantize.model_name
    end

    # poor man's nested_attributes
    if destroyable
      include DestroyableMethods
    else
      include NonDestroyableMethods
    end
  end

  def process(attrs = {})
    self.attributes = attrs
    valid?
  end

  def attributes=(attrs)
    super attrs.to_h
  end
end
