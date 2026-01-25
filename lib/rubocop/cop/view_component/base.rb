# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Shared helper methods for ViewComponent cops
      module Base
        # Check if a class node inherits from ViewComponent::Base or ApplicationComponent
        def view_component_class?(node)
          return false unless node&.class_type?

          parent_class = node.parent_class
          return false unless parent_class

          view_component_parent?(parent_class)
        end

        # Check if node represents ViewComponent::Base or ApplicationComponent
        def view_component_parent?(node)
          return false unless node.const_type?

          source = node.source
          source == "ViewComponent::Base" || source == "ApplicationComponent"
        end

        # Find the enclosing class node
        def enclosing_class(node)
          node.each_ancestor(:class).first
        end

        # Check if node is within a ViewComponent class
        def inside_view_component?(node)
          klass = enclosing_class(node)
          return false unless klass

          view_component_class?(klass)
        end
      end
    end
  end
end
