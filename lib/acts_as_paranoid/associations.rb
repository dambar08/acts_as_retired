# frozen_string_literal: true

module ActsAsRetired
  # This module is included in ActiveRecord::Base to provide paranoid associations.
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method :belongs_to_without_deleted, :belongs_to
        alias_method :belongs_to, :belongs_to_with_retired
      end
    end

    module ClassMethods
      def belongs_to_with_retired(target, scope = nil, options = {})
        if scope.is_a?(Hash)
          options = scope
          scope = nil
        end

        with_retired = options.delete(:with_retired)
        if with_retired
          original_scope = scope
          scope = make_scope_with_retired(scope)
        end

        result = belongs_to_without_deleted(target, scope, **options)

        if with_retired
          options = result.values.last.options
          options[:with_retired] = with_retired
          options[:original_scope] = original_scope
        end

        result
      end

      private

      def make_scope_with_retired(scope)
        if scope
          old_scope = scope
          scope = proc do |*args|
            if old_scope.arity == 0
              instance_exec(&old_scope).with_retired
            else
              old_scope.call(*args).with_retired
            end
          end
        else
          scope = proc do
            if respond_to? :with_retired
              with_retired
            else
              all
            end
          end
        end

        scope
      end
    end
  end
end
