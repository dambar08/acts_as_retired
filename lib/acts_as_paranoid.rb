# frozen_string_literal: true

require "active_record"
require "acts_as_retired/core"
require "acts_as_retired/associations"
require "acts_as_retired/validations"
require "acts_as_retired/relation"
require "acts_as_retired/association_reflection"

module ActsAsRetired
  def paranoid?
    included_modules.include?(ActsAsRetired::Core)
  end

  def validates_as_paranoid
    include ActsAsRetired::Validations
  end

  def acts_as_retired(options = {})
    if !options.is_a?(Hash) && !options.empty?
      raise ArgumentError, "Hash expected, got #{options.class.name}"
    end

    class_attribute :paranoid_configuration

    self.paranoid_configuration = {
      column: "retired_at",
      column_type: "time",
      recover_dependent_associations: true,
      dependent_recovery_window: 2.minutes,
    }
    paranoid_configuration[:deleted_value] = "retired" if options[:column_type] == "string"

    paranoid_configuration.merge!(options) # user options

    unless %w[time boolean string].include? paranoid_configuration[:column_type]
      raise ArgumentError,
            "'time', 'boolean' or 'string' expected for :column_type option," \
            " got #{paranoid_configuration[:column_type]}"
    end

    return if paranoid?

    include ActsAsRetired::Core

    # Magic!
    default_scope { where(paranoid_default_scope) }

    define_deleted_time_scopes if paranoid_column_type == :time
  end
end

ActiveSupport.on_load(:active_record) do
  # Extend ActiveRecord's functionality
  extend ActsAsRetired

  # Extend ActiveRecord::Base with paranoid associations
  include ActsAsRetired::Associations

  # Override ActiveRecord::Relation's behavior
  ActiveRecord::Relation.include ActsAsRetired::Relation

  # Push the recover callback onto the activerecord callback list
  ActiveRecord::Callbacks::CALLBACKS.push(:before_recover, :after_recover)

  ActiveRecord::Reflection::AssociationReflection
    .prepend ActsAsRetired::AssociationReflection
end
