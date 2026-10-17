# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Helpers for navigating the RSpec example-group structure of a spec file.
      #
      # RSpec specs often build a component indirectly, through `described_class`
      # inside a `describe SomeComponent` block or through a `let`/`subject`
      # helper. This module locates those constructs without knowing whether the
      # referenced constant is actually a ViewComponent; that judgement is left
      # to the cop, which has access to the project index.
      module RSpecScope
        EXAMPLE_METHODS = %i[it specify example].freeze
        EXAMPLE_GROUP_METHODS = %i[describe context feature example_group].freeze
        MEMOIZED_HELPER_METHODS = %i[let let! subject subject!].freeze

        def rspec_example_block?(node)
          EXAMPLE_METHODS.include?(node.send_node&.method_name)
        end

        # The constant argument of the nearest enclosing `describe` block, if any.
        # `each_ancestor` yields the closest ancestor first, so an inner
        # `describe` wins over an outer one.
        def enclosing_described_class(node)
          node.each_ancestor(:block) do |ancestor|
            send_node = ancestor.send_node
            next unless send_node&.method?(:describe)

            first_argument = send_node.first_argument
            return first_argument if first_argument&.const_type?
          end

          nil
        end

        def described_class_reference?(node)
          node.send_type? && node.method?(:described_class)
        end

        # Bare method calls (no receiver, no arguments) within +node+, e.g.
        # `component` in `expect(component.title)`.
        def referenced_helper_names(node)
          node.each_node(:send).filter_map do |send_node|
            next unless send_node.receiver.nil?
            next unless send_node.arguments.empty?

            send_node.method_name
          end
        end

        # Maps helper name to block body for every `let`/`subject` defined in an
        # enclosing example group. Inner definitions are visited first and win
        # over outer ones, matching how the name resolves at runtime.
        def helper_definitions(node)
          node.each_ancestor(:block).with_object({}) do |ancestor, definitions|
            next unless example_group_block?(ancestor)

            each_helper_definition(ancestor) do |name, body|
              definitions[name] ||= body
            end
          end
        end

        private

        def each_helper_definition(group)
          return unless group.body

          statements_of(group.body).each do |statement|
            next unless statement.block_type?

            name = helper_name(statement.send_node)
            yield(name, statement.body) if name
          end
        end

        def statements_of(node)
          node.begin_type? ? node.children : [node]
        end

        def helper_name(send_node)
          return nil unless MEMOIZED_HELPER_METHODS.include?(send_node&.method_name)

          first_argument = send_node.first_argument
          return first_argument.value if first_argument&.sym_type?
          return :subject if %i[subject subject!].include?(send_node.method_name)

          nil
        end

        def example_group_block?(node)
          EXAMPLE_GROUP_METHODS.include?(node.send_node&.method_name)
        end
      end
    end
  end
end
