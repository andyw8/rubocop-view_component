# frozen_string_literal: true

require_relative "template_analyzer"

module RuboCop
  module Cop
    module ViewComponent
      # Suggests making helper methods private in ViewComponents.
      #
      # @example
      #   # bad
      #   class CardComponent < ViewComponent::Base
      #     def formatted_title
      #       @title.upcase
      #     end
      #   end
      #
      #   # good
      #   class CardComponent < ViewComponent::Base
      #     private
      #
      #     def formatted_title
      #       @title.upcase
      #     end
      #   end
      #
      class PreferPrivateMethods < RuboCop::Cop::Base
        include ViewComponent::Base
        include TemplateAnalyzer

        MSG = "Consider making this method private. " \
              "Only ViewComponent interface methods should be public."

        def on_class(node)
          return unless view_component_class?(node)

          check_public_methods(node)
        end

        private

        def check_public_methods(class_node)
          current_visibility = :public
          template_method_calls = methods_called_in_templates

          body = class_node.body
          return unless body

          children = body.begin_type? ? body.children : [body]

          children.each do |child|
            if visibility_modifier?(child)
              current_visibility = child.method_name
              next
            end

            next unless child.def_type?
            next unless current_visibility == :public
            next if allowed_public_method?(child.method_name)
            next if template_method_calls.include?(child.method_name)

            add_offense(child)
          end
        end

        def allowed_public_method?(method_name)
          allowed_public_methods.include?(method_name.to_s) ||
            allowed_public_method_patterns.any? { |pattern| method_name.to_s.match?(pattern) }
        end

        def allowed_public_methods
          cop_config.fetch("AllowedPublicMethods", [])
        end

        def allowed_public_method_patterns
          cop_config.fetch("AllowedPublicMethodPatterns", []).map { |pattern| Regexp.new(pattern) }
        end

        def methods_called_in_templates
          component_path = processed_source.file_path
          return Set.new unless component_path

          template_paths = template_paths_for(component_path)
          template_paths.each_with_object(Set.new) do |path, methods|
            methods.merge(extract_method_calls(path))
          end
        rescue => e
          # Graceful degradation on errors
          warn "Warning: Failed to analyze templates: #{e.message}" if ENV["RUBOCOP_DEBUG"]
          Set.new
        end

        def visibility_modifier?(node)
          return false unless node.send_type?
          return false unless node.receiver.nil?

          %i[private protected public].include?(node.method_name)
        end
      end
    end
  end
end
