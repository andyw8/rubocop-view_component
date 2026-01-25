# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Prevents direct access to global state within ViewComponent classes.
      #
      # @example
      #   # bad
      #   class UserComponent < ViewComponent::Base
      #     def admin?
      #       params[:admin]
      #     end
      #   end
      #
      #   # good
      #   class UserComponent < ViewComponent::Base
      #     def initialize(admin:)
      #       @admin = admin
      #     end
      #
      #     def admin?
      #       @admin
      #     end
      #   end
      #
      class NoGlobalState < RuboCop::Cop::Base
        include ViewComponent::Base

        MSG = 'Avoid accessing `%<method>s` directly in ViewComponents. ' \
              'Pass necessary data through the constructor instead.'

        GLOBAL_STATE_METHODS = %i[
          params
          request
          session
          cookies
          flash
        ].freeze

        RESTRICT_ON_SEND = GLOBAL_STATE_METHODS

        def_node_matcher :global_state_access?, <<~PATTERN
          (send nil? ${:params :request :session :cookies :flash} ...)
        PATTERN

        def on_send(node)
          return unless inside_view_component?(node)

          method_name = global_state_access?(node)
          return unless method_name

          add_offense(node, message: format(MSG, method: method_name))
        end
      end
    end
  end
end
