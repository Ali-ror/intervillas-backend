# encoding: UTF-8

module Digineo
  module CountableTags
    extend ActiveSupport::Concern

    included do
      has_many :taggings, as: :taggable

      send(:attr_accessor, :unsaved_taggings)

      has_many :tags, through: :taggings, as: :taggable do
        def <<(tag, amount=nil)
          return super(tag) if amount && amount.to_i < 1

          owner = proxy_association.owner
          owner.unsaved_taggings ||= []
          if owner.new_record?
            tagging = Tagging.new(
              tag:      tag,
              taggable: owner,
              amount:   amount,
            )
            owner.unsaved_taggings << tagging
          else
            tagging = Tagging.where(
              tag_id:        tag.id,
              taggable_id:   owner.id,
              taggable_type: owner.class.to_s
            ).first_or_create!(amount: amount)
          end
        end
      end

      after_save do |record|
        record.unsaved_taggings.each(&:save!) if record.unsaved_taggings
        true
      end
    end

    def tag_with(tag, category, amount=nil)
      category = case category
        when Category then category
        when String   then Category.where(name: category).first_or_create
        when Integer  then Category.find(category)
        else raise TypeError, "no implicit conversion of #{category.class} into Category"
      end

      tag = case tag
        when Tag      then tag
        when String   then Tag.where(name: tag, category_id: category.id).first_or_create(countable: !!amount)
        when Integer  then Tag.find(tag)
        else raise TypeError, "no implicit conversion of #{tag.class} into Tag"
      end

      if amount && amount.to_i == 0
        if tagged_with?(tag)
          self.taggings.where(
            tag_id:         tag.id,
            taggable_type:  self.class.to_s,
            taggable_id:    id,
          ).delete_all
        end
      else
        self.tags.<<(tag, amount)
      end

      self
    end

    def tagged_with?(tag, amount=nil)
      if amount
        amount = amount[:amount] if Hash === amount
        taggings.where(tag_id: tag.id, amount: amount).exists?
      else
        tags.include? tag
      end
    end

    def tags_of_category(category, countable = false)
      if category.kind_of? String
        category = Category.where(name: category).first
      end
      return [] unless category
      self.tags.select do |tag|
        tag.category_id == category.id && tag.countable == countable
      end
    end

    def countable_tags_of_category(category)
      tags_of_category(category, true)
    end

    def amount_of_tag(tag, category = nil)
      unless tag.respond_to? :name
        cat = Category.where(name: category).first
        tag = cat.tags.where(name: tag).first
      end
      taggings.where(tag_id: tag.id).first.try(:amount) || 0
    end
  end
end
