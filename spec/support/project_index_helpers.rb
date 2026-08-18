# frozen_string_literal: true

require "rubydex"

module ViewComponent
  module ProjectIndexHelpers
    DEFAULT_SOURCES = {
      "file:///view_component.rb" => <<~RUBY,
        module ViewComponent
          class Base
          end
        end
      RUBY
      "file:///application_component.rb" => <<~RUBY,
        class ApplicationComponent < ViewComponent::Base
        end
      RUBY
      "file:///user_component.rb" => <<~RUBY
        class UserComponent < ApplicationComponent
        end
      RUBY
    }.freeze

    def build_index(sources = {})
      graph = Rubydex::Graph.new
      DEFAULT_SOURCES.merge(sources).each { |uri, source| graph.index_source(uri, source, "ruby") }
      graph.resolve
      graph
    end

    # Wraps a graph to lazily index the source being inspected when
    # resolve_constant is called. This mirrors how the real RuboCop runner
    # indexes all project files, including the one being inspected.
    class LazyIndex
      def initialize(base_graph, cop)
        @base_graph = base_graph
        @cop = cop
        @rebuilt = false
      end

      def resolve_constant(name, nesting)
        result = @base_graph.resolve_constant(name, nesting)
        return result if result

        rebuild_once
        @base_graph.resolve_constant(name, nesting)
      end

      def method_missing(name, ...)
        @base_graph.send(name, ...)
      end

      def respond_to_missing?(name, include_private = false)
        @base_graph.respond_to?(name, include_private) || super
      end

      private

      def rebuild_once
        return if @rebuilt

        @rebuilt = true
        source = @cop&.processed_source
        return unless source&.raw_source

        @base_graph.index_source("file:///test_source.rb", source.raw_source, "ruby")
        @base_graph.resolve
      end
    end
  end
end
