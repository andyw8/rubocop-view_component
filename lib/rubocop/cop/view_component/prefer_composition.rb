# frozen_string_literal: true

require_relative "template_analyzer"

module RuboCop
  module Cop
    module ViewComponent
      # Detects ViewComponent classes that inherit from another component
      # instead of using composition. Inheriting one component from another
      # causes confusion when each has its own template.
      #
      # A parent is only flagged when its name follows the component convention
      # (the `Component` suffix, or a configured `ComponentNamespaces` prefix)
      # and the project index confirms it is a ViewComponent with its own
      # template. Abstract bases without a template, such as
      # `ApplicationComponent`, are allowed, as are classes the index resolves
      # to something other than a ViewComponent.
      #
      # @example
      #   # bad
      #   class UserCardComponent < BaseCardComponent
      #   end
      #
      #   # good
      #   class UserCardComponent < ViewComponent::Base
      #     # Render BaseCardComponent within template via composition
      #   end
      #
      class PreferComposition < RuboCop::Cop::Base
        include ViewComponent::Base
        include TemplateAnalyzer

        MSG = "Avoid inheriting from another ViewComponent."

        def on_class(node)
          parent_class = node.parent_class
          return unless parent_class&.const_type?
          return unless inheritance_violation?(parent_class)

          add_offense(parent_class)
        end

        private

        # The name heuristic decides which parents are worth checking; the
        # project index then confirms whether the parent really is a concrete
        # ViewComponent. A parent the index can't resolve falls back to the name
        # heuristic so projects without gem indexing are unaffected.
        def inheritance_violation?(parent_class)
          return false unless component_like_parent?(parent_class)

          declaration = resolved_index_declaration(parent_class)
          return true if declaration.nil?
          return false unless view_component_parent?(parent_class)

          parent_has_template?(declaration)
        end

        def parent_has_template?(declaration)
          declaration.definitions.any? do |definition|
            path = definition_source_path(definition)
            path && template_paths_for(path).any?
          end
        rescue StandardError
          false
        end

        def definition_source_path(definition)
          location = definition.location
          return nil unless location.uri.start_with?("file://")

          location.to_file_path
        end

        def component_like_parent?(node)
          source = node.source
          source.end_with?("Component") ||
            component_namespaces.any? { |ns| source.start_with?(ns) }
        end
      end
    end
  end
end
