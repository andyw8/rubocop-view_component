# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Detects ViewComponent classes that appear to be trivial and may not
      # add value over a partial. Components with no methods beyond
      # `initialize`, no slots, and minimal logic may be better as partials.
      #
      # @example
      #   # bad
      #   class SimpleWrapperComponent < ViewComponent::Base
      #     def initialize(content)
      #       @content = content
      #     end
      #   end
      #
      #   # good - has additional methods
      #   class CardComponent < ViewComponent::Base
      #     def initialize(title)
      #       @title = title
      #     end
      #
      #     private
      #
      #     def formatted_title
      #       @title.upcase
      #     end
      #   end
      #
      #   # good - has slots
      #   class ModalComponent < ViewComponent::Base
      #     renders_one :header
      #     renders_many :actions
      #
      #     def initialize(title:)
      #       @title = title
      #     end
      #   end
      #
      class AvoidSingleUseComponents < RuboCop::Cop::Base
        include ViewComponent::Base

        MSG = "This component appears to be trivial. Consider whether " \
              "a partial would be simpler."

        SLOT_METHODS = %i[renders_one renders_many].freeze

        RESTRICT_ON_SEND = SLOT_METHODS

        def on_class(node)
          return unless view_component_class?(node)

          body = node.body
          return add_offense(node.identifier) unless body

          children = body.begin_type? ? body.children : [body]

          return if has_slots?(children)
          return if has_non_initialize_methods?(children)

          add_offense(node.identifier)
        end

        private

        def has_slots?(children)
          children.any? do |child|
            child.send_type? && SLOT_METHODS.include?(child.method_name)
          end
        end

        def has_non_initialize_methods?(children)
          children.any? do |child|
            next false unless child.def_type?

            child.method_name != :initialize
          end
        end
      end
    end
  end
end
