# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Shared helper methods for ViewComponent cops
      module Base
        # Check if a class node inherits from ViewComponent::Base or ApplicationComponent
        def view_component_class?(node)
          return false unless node&.class_type?

          class_source = node.identifier.source
          return true if component_namespaces.any? { |ns| class_source.start_with?(ns) }

          parent_class = node.parent_class
          return false unless parent_class

          view_component_parent?(parent_class)
        end

        # Check if node represents a configured parent class
        def view_component_parent?(node)
          return false unless node.const_type?

          (cop_config["ViewComponentParentClasses"] || []).include?(node.source)
        end

        # Check if a class node is itself one of the registered parent classes.
        def view_component_parent_class?(node)
          return false unless node&.class_type?

          (cop_config["ViewComponentParentClasses"] || []).include?(fully_qualified_name(node))
        end

        def fully_qualified_name(node)
          namespace = node.parent_module_name
          short_name = node.identifier.source
          return short_name if namespace.nil? || namespace == "Object"

          "#{namespace}::#{short_name}"
        end

        def component_namespaces
          cop_config["ComponentNamespaces"] || []
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
