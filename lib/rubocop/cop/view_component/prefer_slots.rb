# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Detects parameters that accept HTML content and suggests using slots.
      #
      # @example
      #   # bad
      #   class ModalComponent < ViewComponent::Base
      #     def initialize(title:, body_html:)
      #       @title = title
      #       @body_html = body_html
      #     end
      #   end
      #
      #   # good
      #   class ModalComponent < ViewComponent::Base
      #     renders_one :body
      #
      #     def initialize(title:)
      #       @title = title
      #     end
      #   end
      #
      class PreferSlots < RuboCop::Cop::Base
        include ViewComponent::Base

        MSG = "Consider using `%<slot_method>s` instead of passing HTML " \
              "as a parameter. This maintains Rails' automatic HTML escaping."

        HTML_PARAM_PATTERNS = [
          /_html$/,
          /_content$/,
          /^html_/,
          /^content$/
        ].freeze

        # Exclude common non-HTML parameters
        EXCLUDED_PARAMS = %i[
          html_class
          html_classes
          html_id
          html_tag
        ].freeze

        def_node_search :html_safe_call?, "(send _ :html_safe)"

        def on_class(node)
          return unless view_component_class?(node)

          initialize_method = find_initialize(node)
          return unless initialize_method

          check_initialize_params(initialize_method)
        end

        private

        def find_initialize(class_node)
          class_node.each_descendant(:def).find do |def_node|
            def_node.method_name == :initialize
          end
        end

        def check_initialize_params(initialize_node)
          initialize_node.arguments.each do |arg|
            next unless arg.kwoptarg_type? || arg.kwarg_type?

            param_name = arg.children[0]

            # Skip excluded parameters
            next if EXCLUDED_PARAMS.include?(param_name)

            # Check parameter name patterns
            if html_param_name?(param_name)
              suggested_slot = suggest_slot_name(param_name)
              add_offense(arg, message: format(MSG, slot_method: suggested_slot))
              next
            end

            # Check for html_safe in default value
            if arg.kwoptarg_type? && html_safe_call?(arg)
              suggested_slot = suggest_slot_name(param_name)
              add_offense(arg, message: format(MSG, slot_method: suggested_slot))
            end
          end
        end

        def html_param_name?(name)
          HTML_PARAM_PATTERNS.any? { |pattern| pattern.match?(name.to_s) }
        end

        def suggest_slot_name(param_name)
          clean_name = param_name.to_s
            .sub(/_html$/, "")
            .sub(/_content$/, "")
            .sub(/^html_/, "")

          "renders_one :#{clean_name}"
        end
      end
    end
  end
end
