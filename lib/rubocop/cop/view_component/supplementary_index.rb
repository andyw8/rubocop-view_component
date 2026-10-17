# frozen_string_literal: true

require "digest"
require "rubydex"
require "uri"

module RuboCop
  module Cop
    module ViewComponent
      # Extends the project index with `AdditionalSourcePaths`: source
      # directories the cops index themselves, so a chain that passes through a
      # gem RuboCop does not index is still resolvable. The motivating case is a
      # Rails engine's `app/components`, which `AllCops/ProjectIndexIncludesGems`
      # misses because it only indexes a gem's `lib`.
      module SupplementaryIndex
        # A minimal stand-in for the framework base class, indexed alongside the
        # configured paths so ancestry there can still reach
        # `ViewComponent::Base` without indexing the whole view_component gem.
        BASE_URI = "rubydex:view_component_base"
        BASE_SOURCE = <<~RUBY
          module ViewComponent
            class Base
            end
          end
        RUBY

        # RuboCop's cache key, extended with the supplementary files' mtimes:
        # those files are not part of RuboCop's own index documents, so a change
        # to one would otherwise not invalidate a cached result.
        def external_dependency_checksum
          base = super
          extra = supplementary_files_checksum
          return base if extra.nil?
          return extra if base.nil?

          Digest::SHA1.hexdigest("#{base}:#{extra}")
        end

        private

        # Resolve through RuboCop's project index first, then the supplementary one.
        def resolve_constant_in_index(const_node)
          super || resolve_constant_in_graph(supplementary_index, const_node)
        end

        def resolve_constant_in_graph(graph, const_node)
          return nil unless graph

          segments = const_node.const_name.split("::")
          # The inspected file's lexical scopes live in the project index, not
          # in the supplementary one, so resolving through them can fail (a
          # scope name like `Ui` is simply absent here). Try them first, then
          # resolve from the top level.
          nesting_candidates(const_node).each do |nesting|
            declaration = resolve_segments(graph, segments, nesting)
            return declaration if declaration
          end
          nil
        end

        def nesting_candidates(const_node)
          return [[]] if const_node.absolute?

          [lexical_nesting_of(const_node), []].uniq
        end

        def resolve_segments(graph, segments, nesting)
          declaration = graph.resolve_constant(segments.first, nesting)
          return nil unless declaration

          segments.drop(1).each do |segment|
            return nil unless declaration.is_a?(Rubydex::Namespace)

            declaration = declaration.find_member(segment)
            return nil unless declaration
          end
          declaration
        end

        # Built once per cop and only when the option is set.
        def supplementary_index
          return @supplementary_index if defined?(@supplementary_index)

          @supplementary_index = build_supplementary_index
        end

        def build_supplementary_index
          files = supplementary_source_files
          return nil if files.empty?

          graph = Rubydex::Graph.new
          graph.index_source(BASE_URI, BASE_SOURCE, "ruby")
          index_files(graph, files)
          graph.resolve
          graph
        rescue StandardError
          nil
        end

        def index_files(graph, files)
          # File by file, not `index_all`: in a forked RuboCop worker
          # `index_all` crashes once the parent has built its own graph, while
          # `index_source` is safe.
          files.each do |file|
            graph.index_source(file_uri(file), File.read(file), "ruby")
          rescue StandardError
            next
          end
        end

        def file_uri(file)
          "file://#{URI::DEFAULT_PARSER.escape(file)}"
        end

        def supplementary_source_files
          configured_source_paths.flat_map { |path| Dir.glob(File.join(path, "**", "*.rb")) }.uniq.sort
        end

        def configured_source_paths
          Array(cop_config["AdditionalSourcePaths"]).filter_map do |path|
            expanded = File.expand_path(path, config.base_dir_for_path_parameters)
            expanded if File.directory?(expanded)
          end
        end

        def supplementary_files_checksum
          files = supplementary_source_files
          return nil if files.empty?

          Digest::SHA1.hexdigest(files.map { |file| file_signature(file) }.join("\n"))
        end

        def file_signature(file)
          stat = File.stat(file)
          "#{file}:#{stat.mtime.to_f}:#{stat.size}"
        rescue StandardError
          file
        end
      end
    end
  end
end
