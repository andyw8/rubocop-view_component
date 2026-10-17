# frozen_string_literal: true

require_relative "rspec_scope"

module RuboCop
  module Cop
    module ViewComponent
      # Ensures that ViewComponent tests use `render_inline` to test rendered output
      # rather than testing component methods directly.
      #
      # This cop is only enabled for test files by default (see config).
      #
      # A test is considered to instantiate a component when it builds one
      # directly (`UserComponent.new`), through `described_class.new` inside a
      # `describe UserComponent` block, or by referencing a `let`/`subject`
      # helper whose body instantiates a component.
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
      #   # bad
      #   describe TitleComponent do
      #     it "formats the title" do
      #       component = described_class.new("hello")
      #       expect(component.formatted_title).to eq("HELLO")
      #     end
      #   end
      #
      #   # good
      #   describe TitleComponent do
      #     it "formats the title" do
      #       render_inline described_class.new("hello")
      #       expect(page).to have_text("HELLO")
      #     end
      #   end
      #
      #   # bad
      #   let(:component) { TitleComponent.new("hello") }
      #
      #   it "formats the title" do
      #     expect(component.formatted_title).to eq("HELLO")
      #   end
      #
      class TestRenderedOutput < RuboCop::Cop::Base
        include ViewComponent::Base
        include RSpecScope

        MSG = "Test instantiates a component but doesn't use `render_inline` or `render_preview`. " \
              "Test the rendered output instead of component methods directly."

        RENDER_METHODS = %i[render_inline render_preview].freeze

        # Check Minitest-style test methods
        def on_def(node)
          return unless within_test_paths?

          method_name = node.method_name.to_s
          return unless method_name.start_with?("test_")
          return unless instantiates_component?(node)
          return if renders_output?(node)

          add_offense(node)
        end

        # Check RSpec-style it blocks
        def on_block(node)
          return unless within_test_paths?
          return unless rspec_example_block?(node)
          return unless instantiates_component?(node)
          return if renders_output?(node)

          add_offense(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def within_test_paths?
          test_paths = cop_config["TestPaths"]
          return true if test_paths.nil? || test_paths.empty?

          file_path = processed_source.path
          test_paths.any? { |path| file_path.include?(path) }
        end

        def instantiates_component?(node)
          component_new_call?(node) ||
            referenced_helper?(node) { |body| component_new_call?(body) }
        end

        def renders_output?(node)
          render_call?(node) ||
            referenced_helper?(node) { |body| render_call?(body) }
        end

        # True when the node calls `.new` on a component constant or on
        # `described_class` within a `describe` block.
        def component_new_call?(node)
          node.each_node(:send).any? do |send_node|
            next unless send_node.method?(:new)
            next if inside_error_expectation?(send_node)

            component_receiver?(send_node.receiver)
          end
        end

        # A component built inside `expect { ... }.to raise_error` is exercising
        # initialisation behaviour rather than rendered output, so there is
        # nothing to render.
        def inside_error_expectation?(node)
          node.each_ancestor(:block).any? do |ancestor|
            ancestor.send_node&.method?(:expect) && error_expectation?(ancestor)
          end
        end

        def error_expectation?(expect_block)
          parent = expect_block.parent
          return false unless parent&.send_type?
          return false unless %i[to not_to].include?(parent.method_name)

          error_matcher?(parent.first_argument)
        end

        def error_matcher?(matcher)
          matcher = matcher.send_node if matcher&.block_type?
          matcher&.send_type? &&
            %i[raise_error raise_exception].include?(matcher.method_name)
        end

        def component_receiver?(receiver)
          return false unless receiver
          return view_component_parent?(receiver) if receiver.const_type?
          return false unless described_class_reference?(receiver)

          described_class = enclosing_described_class(receiver)
          described_class && view_component_parent?(described_class)
        end

        def render_call?(node)
          node.each_node(:send).any? do |send_node|
            RENDER_METHODS.include?(send_node.method_name)
          end
        end

        # True when the node references a `let`/`subject` helper whose body
        # satisfies the given block.
        def referenced_helper?(node)
          helper_bodies = helper_definitions(node)

          referenced_helper_names(node).any? do |name|
            body = helper_bodies[name]
            body && yield(body)
          end
        end
      end
    end
  end
end
