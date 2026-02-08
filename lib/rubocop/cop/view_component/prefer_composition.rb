# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Detects ViewComponent classes that inherit from another component
      # instead of using composition. Inheriting one component from another
      # causes confusion when each has its own template.
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

        MSG = "Avoid inheriting from another ViewComponent."

        def on_class(node)
          parent_class = node.parent_class
          return unless parent_class
          return if view_component_parent?(parent_class)
          return unless component_like_parent?(parent_class)

          add_offense(parent_class)
        end

        private

        def component_like_parent?(node)
          return false unless node.const_type?

          node.source.end_with?("Component")
        end
      end
    end
  end
end
