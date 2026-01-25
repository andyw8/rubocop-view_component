# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Enforces that ViewComponent classes end with the `Component` suffix.
      #
      # @example
      #   # bad
      #   class FooBar < ViewComponent::Base
      #   end
      #
      #   # good
      #   class FooBarComponent < ViewComponent::Base
      #   end
      #
      class ComponentSuffix < RuboCop::Cop::Base
        include ViewComponent::Base

        MSG = "ViewComponent class names should end with `Component`."

        def on_class(node)
          return unless view_component_class?(node)

          class_name = node.identifier.source
          return if class_name.end_with?("Component")

          add_offense(node.identifier)
        end
      end
    end
  end
end
