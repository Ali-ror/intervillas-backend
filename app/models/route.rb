# == Schema Information
#
# Table name: routes
#
#  action           :string
#  controller       :string
#  h1               :string
#  html_title       :string
#  id               :integer          not null, primary key
#  meta_description :text
#  name             :string
#  path             :string           not null
#  resource_id      :integer
#  resource_type    :string
#
# Indexes
#
#  index_routes_on_controller_and_action          (controller,action)
#  index_routes_on_path                           (path)
#  index_routes_on_resource_type_and_resource_id  (resource_type,resource_id) UNIQUE
#

class Route < ApplicationRecord
  translates :html_title, :meta_description, :h1 # rubocop:disable Naming/VariableNumber
  include Digineo::I18n

  validates :path,
    presence: { unless: ->(route) { route.path == "" } }

  belongs_to :resource,
    polymorphic: true,
    touch:       true,
    optional:    true # optional, weil NULL erlaubt

  after_save :reload_routes

  default_scope { includes(:translations) }
  scope :with_name, -> { where.not(name: nil) }

  def reload_routes
    return true if Rails.env.test?

    logger.debug { "reloading routes..." }
    Intervillas::Application.reload_routes!
  end

  def resource_type=(value)
    super value.presence
  end

  def self.inject_routes!(router) # rubocop:disable Metrics/CyclomaticComplexity:
    includes(:translations, :resource).with_name.each do |route|
      router.get "/#{route.path}",
        controller: route.controller,
        action:     route.action,
        id:         route.resource&.to_param,
        as:         route.name
    end

    includes(:translations, :resource).where(name: nil, controller: "admin/pages").each do |route|
      router.get "/#{route.path}",
        controller: route.controller,
        action:     route.action,
        id:         route.resource&.to_param,
        as:         nil # unnamed
    end
  rescue *INJECTION_ERRORS => err
    case err.message
    when /Name or service not known/
      # ignore: connection can't be established, e.g. on CI without DB service
    when /does not exist|could not find your database/
      # ignore: we're bootstrapping the DB, e.g. when running db:setup
    else
      raise
    end

    warn "Injecting routes failed with #{err.class}."
    warn "You can safely ignore this error, if you're just setting up the database."
    warn err.message.lines.map { "\t#{_1}" }.join
  end

  INJECTION_ERRORS = [
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::NoDatabaseError,
    ActiveRecord::StatementInvalid,
    PG::ConnectionBad,
  ].freeze
end
