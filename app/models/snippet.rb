# == Schema Information
#
# Table name: snippets
#
#  id           :bigint           not null, primary key
#  content_html :text             not null
#  content_md   :text             not null
#  key          :string           not null
#  title        :string           not null
#
# Indexes
#
#  index_snippets_on_key  (key) UNIQUE
#

class Snippet < ApplicationRecord
  translates :content_md, :content_html,
    touch: true
  include Digineo::I18n

  validates :key,
    presence:   true,
    uniqueness: true

  validates :title,
    presence: true

  before_save :sync_html

  after_commit on: %i[create update] do
    next unless key == "house_rules"

    MyBookingPal::Product.where.not(foreign_id: nil).find_each(&:update_remote!)
  end

  def self.content_for(key)
    s = includes(:translations).find_by(key:)
    s&.content_html.presence
  end

  def self.house_rules
    s = includes(:translations).find_by(key: "house_rules")
    return s if s.present?

    texts = YAML.load_file Rails.root.join("config/house_rules.yml")
    Snippet.new(
      title:         "Haus-Regeln (für MyBookingPal)",
      key:           "house_rules",
      de_content_md: texts["de"],
      en_content_md: texts["en"],
    ).tap(&:save!)
  end

  private

  def sync_html
    self.de_content_html = render_md(de_content_md)
    self.en_content_html = render_md(en_content_md)
  end

  def render_md(content)
    RenderKramdown.new(content.presence || "").to_html
  end
end
