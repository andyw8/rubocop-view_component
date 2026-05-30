# frozen_string_literal: true

module RuboCop
  module ViewComponent
    # Builds and caches a set of all known ViewComponent parent classes by
    # scanning app/components/ and following the inheritance graph transitively.
    module ParentClassIndex
      extend self

      BUILTIN_ROOTS = %w[ViewComponent::Base ApplicationComponent].freeze

      def known_parent?(class_name, cop_config)
        index(cop_config).include?(class_name)
      end

      def reset!
        @index = nil
      end

      private

      def index(cop_config)
        @index ||= build_index(cop_config)
      end

      def build_index(cop_config)
        configured = Array(cop_config["ViewComponentParentClasses"])
        roots = (BUILTIN_ROOTS + configured).to_set
        graph = scan_components
        expand_transitively(graph, roots)
      end

      def scan_components
        Dir.glob("app/components/**/*.rb").each_with_object({}) do |path, graph|
          source = RuboCop::ProcessedSource.from_file(path, RUBY_VERSION.to_f)
          next unless source.valid_syntax?

          source.ast&.each_node(:class) do |class_node|
            next unless class_node.parent_class

            child = class_name_from(class_node)
            parent = class_node.parent_class.source
            graph[child] = parent if child && parent
          end
        end
      end

      def class_name_from(class_node)
        namespace = class_node.parent_module_name
        short = class_node.identifier.source
        return short if namespace.nil? || namespace == "Object"

        "#{namespace}::#{short}"
      end

      def expand_transitively(graph, roots)
        loop do
          new_roots = graph.filter_map { |child, parent| child if !roots.include?(child) && roots.include?(parent) }
          break if new_roots.empty?

          roots.merge(new_roots)
        end
        roots
      end
    end
  end
end
