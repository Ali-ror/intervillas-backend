# == Schema Information
#
# Table name: page_views
#
#  date  :date             not null, primary key
#  item  :string           not null, primary key
#  total :integer          default(0), not null
#
# Indexes
#
#  index_page_views_on_date_and_item  (date,item) UNIQUE
#

class PageView < ApplicationRecord
  self.primary_key = [:date, :item]

  TRACK_SQL = <<~SQL.squish.freeze
    insert into page_views (date, item, total)
      values (%<date>s, %<item>s, 1)
      on conflict (date, item)
        do update set total = page_views.total + 1
  SQL

  def self.track!(date, item)
    ActiveRecord::Base.connection.tap {|conn|
      sql = format TRACK_SQL,
        date: conn.quote(date.strftime("%Y-%m-%d")),
        item: conn.quote(item)
      conn.execute sql
    }
    true
  end

  def self.summarize(start_on: nil, end_on: nil)
    scope = where("page_views.item like ?", "map/%")
    scope = scope.where("page_views.date >= ?", start_on) if start_on
    scope = scope.where("page_views.date <= ?", end_on)   if end_on

    summary = Hash.new {|h,k| h[k] = Hash.new(0) }

    scope.find_in_batches do |views|
      views.each do |view|
        it = if view.item == "map/static"
          "static"
        elsif view.item.start_with?("map/admin/")
          "admin"
        elsif view.item.start_with?("map/js/")
          summary[view.date]["villa"] -= view.total
          "js"
        else
          "villa"
        end

        summary[view.date][it] += view.total
      end
    end

    summary.sort_by {|k,_| k }.to_h
  end
end
