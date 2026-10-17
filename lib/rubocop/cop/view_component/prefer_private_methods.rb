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

        MSG = "Consider making `%<method_name>s` private. " \
              "Only ViewComponent interface methods should be public."

        def on_class(node)
          return unless view_component_class?(node)

          check_public_methods(node)
        end

        private

        def check_public_methods(class_node)
          body = class_node.body
          return unless body

          children = body.begin_type? ? body.children : [body]
          check_children(children, methods_called_in_templates, indexed_visibilities(class_node))
        end

        def check_children(children, template_method_calls, indexed_visibilities)
          current_visibility = :public

          children.each do |child|
            if bare_visibility_modifier?(child)
              current_visibility = child.method_name
            elsif child.def_type?
              visibility = indexed_visibilities.fetch(child.method_name, current_visibility)
              next unless should_flag?(child, visibility, template_method_calls)

              add_offense(child, message: format(MSG, method_name: child.method_name))
            end
          end
        end

        def should_flag?(child, visibility, template_method_calls)
          visibility == :public &&
            !allowed_public_method?(child.method_name) &&
            !template_method_calls.include?(child.method_name)
        end

        # The effective visibility of each method defined in the class, taken
        # from the project index. This covers the forms an in-file walk cannot
        # see: `private :name`, `private def name`, `public :name`, and
        # visibility applied in another file. Empty when the class is not in
        # the index (for example with `ComponentNamespaces`, which does not
        # require one), in which case the in-file keyword below is used
        # instead.
        def indexed_visibilities(class_node)
          return {} unless project_index && class_node.identifier

          declaration = resolved_index_declaration(class_node.identifier)
          return {} unless declaration.is_a?(Rubydex::Namespace)

          declaration.members.each_with_object({}) do |member, visibilities|
            next unless member.is_a?(Rubydex::Method)

            visibilities[member_method_name(member)] = member.visibility
          end
        rescue StandardError
          {}
        end

        def member_method_name(member)
          member.unqualified_name.sub(/\(.*\)\z/, "").to_sym
        end

        # A `private`/`protected`/`public` call with no arguments, which
        # changes the visibility of every method that follows it. Forms that
        # name their methods do not change it: `private :name` and
        # `private def name` are handled by the index above.
        def bare_visibility_modifier?(node)
          return false unless node.send_type?
          return false unless node.receiver.nil?
          return false unless %i[private protected public].include?(node.method_name)

          node.arguments.empty?
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
        rescue StandardError => e
          warn "Warning: Failed to analyze templates: #{e.message}" if ENV["RUBOCOP_DEBUG"]
          Set.new
        end
      end
    end
  end
end
