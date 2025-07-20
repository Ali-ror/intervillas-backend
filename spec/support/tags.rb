module TagFixtures
  def restore_tags!
    fixtures = YAML.safe_load Rails.root.join("spec/fixtures/tags.yml").read

    fixtures.each do |cat_name, cfg|
      category = create :category, name: cat_name, multiple_types: cfg["multiple_types"]
      cfg["tags"].each do |tag_name, tr|
        tag = create :tag, category: category, name: tag_name, countable: tr.size == 6
        if tag.countable?
          tag.translations.create locale: :de, description: tr[0], name_one: tr[1], name_other: tr[2]
          tag.translations.create locale: :en, description: tr[3], name_one: tr[4], name_other: tr[5]
        else
          tag.translations.create locale: :de, description: tr[0],                  name_other: tr[1]
          tag.translations.create locale: :en, description: tr[2],                  name_other: tr[3]
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include TagFixtures
end
