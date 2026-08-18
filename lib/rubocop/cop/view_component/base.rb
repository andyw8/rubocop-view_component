# frozen_string_literal: true

require "rubydex"

module RuboCop
  module Cop
    module ViewComponent
      # Shared helper methods for ViewComponent cops.
      # Requires rubydex with UseProjectIndex: true for ancestry resolution.
      module Base
        include ProjectIndexHelp

        VC_BASE = "ViewComponent::Base"

        # Check if a class node inherits from ViewComponent::Base
        def view_component_class?(node)
          return false unless node&.class_type?

          class_source = fully_qualified_name(node)
          return true if component_namespaces.any? { |ns| class_source.start_with?(ns) }

          parent_class = node.parent_class
          return false unless parent_class

          view_component_parent?(parent_class)
        end

        # Check if a constant node resolves to a class with ViewComponent::Base as ancestor
        def view_component_parent?(node)
          return false unless node.const_type?
          return false unless project_index

          declaration = resolve_constant_in_index(node)
          return false unless declaration.respond_to?(:has_ancestor?)

          declaration.name == VC_BASE || declaration.has_ancestor?(VC_BASE)
        end

        # Check if a class node is itself an abstract parent class
        # (has ViewComponent::Base as ancestor and has descendants in the project)
        def view_component_parent_class?(node)
          return false unless node&.class_type?
          return false unless project_index

          declaration = resolve_constant_in_index(node.identifier)
          return false unless declaration.respond_to?(:has_ancestor?)

          declaration.has_ancestor?(VC_BASE) &&
            declaration.descendants.any? { |d| d.name != declaration.name }
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
