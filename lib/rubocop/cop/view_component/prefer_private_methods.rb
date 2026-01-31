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

        ALLOWED_PUBLIC_METHODS = %i[
          initialize
          call
          before_render
          before_render_check
          render?
        ].freeze

        def on_class(node)
          return unless view_component_class?(node)

          check_public_methods(node)
        end

        private

        def check_public_methods(class_node)
          current_visibility = :public
          template_method_calls = methods_called_in_templates

          class_node.body&.each_child_node do |child|
            if visibility_modifier?(child)
              current_visibility = child.method_name
              next
            end

            next unless child.def_type?
            next unless current_visibility == :public
            next if ALLOWED_PUBLIC_METHODS.include?(child.method_name)
            next if template_method_calls.include?(child.method_name)

            add_offense(child)
          end
        end

        def methods_called_in_templates
          component_path = processed_source.file_path
          return Set.new unless component_path

          template_paths = template_paths_for(component_path)
          template_paths.each_with_object(Set.new) do |path, methods|
            methods.merge(extract_method_calls(path))
          end
        rescue
          # Graceful degradation on errors
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
