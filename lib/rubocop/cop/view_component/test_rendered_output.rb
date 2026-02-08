# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Detects test assertions against component instance methods
      # and suggests using `render_inline` with content assertions instead.
      #
      # This cop is only enabled for test files by default (see config).
      #
      # @example
      #   # bad
      #   component = TitleComponent.new("hello")
      #   assert_equal "HELLO", component.formatted_title
      #
      #   # bad
      #   expect(component.formatted_title).to eq("HELLO")
      #
      #   # good
      #   render_inline TitleComponent.new("hello")
      #   assert_text "HELLO"
      #
      #   # good
      #   expect(page).to have_text("HELLO")
      #
      class TestRenderedOutput < RuboCop::Cop::Base
        MSG = "Avoid testing ViewComponent methods directly. " \
              "Use `render_inline` and assert against rendered output instead."

        # Track local variable assignments of component instances
        def on_lvasgn(node)
          var_name = node.children[0]
          value = node.children[1]
          return unless value

          if component_new_call?(value)
            component_variables[var_name] = true
          end
        end

        # Detect method calls on component instances
        def on_send(node)
          receiver = node.receiver
          return unless receiver

          # Inline: UserComponent.new("hello").some_method
          if component_new_call?(receiver)
            return if configuration_method?(node.method_name)

            add_offense(node)
            return
          end

          # Variable: component.some_method
          return unless receiver.lvar_type?

          var_name = receiver.children[0]
          return unless component_variables[var_name]
          return if ignored_method?(node.method_name)

          add_offense(node)
        end

        private

        def component_variables
          @component_variables ||= {}
        end

        def component_new_call?(node)
          return false unless node.send_type?
          return false unless node.method_name == :new

          receiver = node.receiver
          return false unless receiver&.const_type?

          const_name(receiver).end_with?("Component")
        end

        def const_name(node)
          return "" unless node.const_type?

          if node.namespace
            "#{const_name(node.namespace)}::#{node.children.last}"
          else
            node.children.last.to_s
          end
        end

        def ignored_method?(method_name)
          %i[class is_a? kind_of? instance_of? respond_to? nil?].include?(method_name)
        end

        def configuration_method?(method_name)
          # Allow ViewComponent slot and content configuration methods
          method_name.to_s.start_with?("with_")
        end
      end
    end
  end
end
