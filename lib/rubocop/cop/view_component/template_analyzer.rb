# frozen_string_literal: true

require "herb"

module RuboCop
  module Cop
    module ViewComponent
      # Helper module for analyzing ViewComponent ERB templates
      module TemplateAnalyzer
        # Find template file paths for a component
        # @param component_path [String] Path to the component Ruby file
        # @return [Array<String>] Array of template file paths
        def template_paths_for(component_path)
          return [] unless component_path

          base_path = component_path.sub(/\.rb$/, "")
          component_dir = File.dirname(component_path)
          component_name = File.basename(component_path, ".rb")
          sidecar_dir = File.join(component_dir, component_name)

          paths = sibling_templates(base_path) + sidecar_templates(sidecar_dir, component_name)
          paths.uniq
        end

        def sibling_templates(base_path)
          paths = []
          sibling = "#{base_path}.html.erb"
          paths << sibling if File.exist?(sibling)
          paths.concat(Dir.glob("#{base_path}.*.html.erb"))
          paths
        end

        def sidecar_templates(sidecar_dir, component_name)
          paths = []
          sidecar = File.join(sidecar_dir, "#{component_name}.html.erb")
          paths << sidecar if File.exist?(sidecar)
          paths.concat(Dir.glob(File.join(sidecar_dir, "#{component_name}.*.html.erb")))
          paths
        end

        # Extract method calls from an ERB template
        # @param template_path [String] Path to the ERB template file
        # @return [Set<Symbol>] Set of method names called in the template
        def extract_method_calls(template_path)
          return Set.new unless File.exist?(template_path)

          source = File.read(template_path)
          ruby_code = Herb.extract_ruby(source)

          # Parse the extracted Ruby code
          parse_ruby_for_method_calls(ruby_code)
        rescue StandardError => e
          # Graceful degradation on parse errors
          warn "Warning: Failed to parse template #{template_path}: #{e.message}" if ENV["RUBOCOP_DEBUG"]
          Set.new
        end

        private

        # Parse Ruby code and extract method calls (send nodes with nil receiver)
        def parse_ruby_for_method_calls(ruby_code)
          # Use RuboCop's ProcessedSource to parse Ruby code
          processed = RuboCop::ProcessedSource.new(
            ruby_code,
            RuboCop::TargetRuby.supported_versions.max,
            "(template)"
          )

          return Set.new unless processed.valid_syntax?

          method_calls = Set.new
          traverse_for_method_calls(processed.ast, method_calls) if processed.ast
          method_calls
        end

        # Recursively traverse AST to find method calls
        def traverse_for_method_calls(node, method_calls)
          return unless node.respond_to?(:type)

          # Look for send nodes with nil receiver (local method calls)
          if node.send_type? && node.receiver.nil?
            method_name = node.method_name
            method_calls.add(method_name)
          end

          # Recursively traverse children
          node.each_child_node do |child|
            traverse_for_method_calls(child, method_calls)
          end
        end
      end
    end
  end
end
