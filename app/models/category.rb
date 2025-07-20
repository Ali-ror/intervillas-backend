# encoding: UTF-8
# == Schema Information
#
# Table name: categories
#
#  created_at     :datetime         not null
#  id             :integer          not null, primary key
#  multiple_types :string
#  name           :string           not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_categories_on_name  (name) UNIQUE
#

class Category < ApplicationRecord
  validates_presence_of :name
  validates_uniqueness_of :name

  serialize :multiple_types

  has_many :areas
  has_many :tags
  has_many :descriptions

  def to_s
    I18n.t name, scope: :category
  end

  class << self
    def tags_for(name)
      return [] unless cat = find_by(name: name)
      cat.tags.pluck(:name)
    end

    def tag_names_for(category_name)
      tags_for(category_name).map do |tag|
        [category_name, tag].join('_').to_sym
      end
    end

    def export_fixtures(io: $stdout)
      raise RuntimeError, "only for development" unless Rails.env.development?

      fixtures = includes(tags: :translations).order(:name).each_with_object({}) { |cat, list|
        tags = cat.tags.map { |t|
          de = t.translations.find { |tr| tr.locale == :de }
          en = t.translations.find { |tr| tr.locale == :en }

          names = if t.countable?
            [
              de.description,
              de.name_one,
              de.name_other,
              en.description,
              en.name_one,
              en.name_other
            ]
          else
            [
              de.description,
              de.name_other,
              en.description,
              en.name_other
            ]
          end

          [t.name, names]
        }.sort.to_h

        if tags.any?
          list[cat.name] = {
            "multiple_types" => cat.multiple_types.presence,
            "tags"           => tags,
          }.compact
        end
      }

      io.puts <<~HEADER, fixtures.to_yaml.sub(/\A---\n/, "")
        # Auto-generated with `Category.export_fixtures`. DO NOT EDIT!
        # Date: #{Time.current}
      HEADER
    end
  end
end
