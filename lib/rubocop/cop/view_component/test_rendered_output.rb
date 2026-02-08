# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Ensures that ViewComponent tests use `render_inline` to test rendered output
      # rather than testing component methods directly.
      #
      # This cop is only enabled for test files by default (see config).
      #
      # @example
      #   # bad
      #   def test_formatted_title
      #     component = TitleComponent.new("hello")
      #     assert_equal "HELLO", component.formatted_title
      #   end
      #
      #   # good
      #   def test_formatted_title
      #     render_inline TitleComponent.new("hello")
      #     assert_text "HELLO"
      #   end
      #
      class TestRenderedOutput < RuboCop::Cop::Base
        MSG = "Test instantiates a component but doesn't use `render_inline` or `render_preview`. " \
              "Test the rendered output instead of component methods directly."

        # Check Minitest-style test methods
        def on_def(node)
          method_name = node.method_name.to_s
          return unless method_name.start_with?("test_")
          return unless instantiates_component?(node)
          return if contains_render_method?(node)

          add_offense(node)
        end

        # Check RSpec-style it blocks
        def on_block(node)
          return unless rspec_it_block?(node)
          return unless instantiates_component?(node)
          return if contains_render_method?(node)

          add_offense(node)
        end

        private

        def instantiates_component?(node)
          node.each_descendant(:send).any? do |send_node|
            next unless send_node.method_name == :new

            receiver = send_node.receiver
            next unless receiver&.const_type?

            const_name(receiver).end_with?("Component")
          end
        end

        def contains_render_method?(node)
          node.each_descendant(:send).any? do |send_node|
            %i[render_inline render_preview].include?(send_node.method_name)
          end
        end

        def const_name(node)
          return "" unless node.const_type?

          if node.namespace
            "#{const_name(node.namespace)}::#{node.children.last}"
          else
            node.children.last.to_s
          end
        end

        def rspec_it_block?(node)
          send_node = node.send_node
          return false unless send_node

          %i[it specify example].include?(send_node.method_name)
        end
      end
    end
  end
end
