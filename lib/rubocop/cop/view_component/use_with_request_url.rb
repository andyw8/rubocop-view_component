# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Ensures that ViewComponent tests use `with_request_url` when calling
      # URL helpers inside a test that renders a component.
      #
      # Rails URL helpers require `request.path_parameters` to be set correctly,
      # or they raise `ActionController::UrlGenerationError`. The
      # `with_request_url` helper sets these parameters for the duration of the
      # block.
      #
      # @example
      #   # bad
      #   def test_link
      #     render_inline MyComponent.new
      #     assert_selector "a[href='#{root_path}']"
      #   end
      #
      #   # good
      #   def test_link
      #     with_request_url "/" do
      #       render_inline MyComponent.new
      #       assert_selector "a[href='#{root_path}']"
      #     end
      #   end
      #
      #   # bad
      #   it "renders a link" do
      #     render_inline MyComponent.new
      #     expect(page).to have_selector("a[href='#{user_path(1)}']")
      #   end
      #
      #   # good
      #   it "renders a link" do
      #     with_request_url "/users/1" do
      #       render_inline MyComponent.new
      #       expect(page).to have_selector("a[href='#{user_path(1)}']")
      #     end
      #   end
      #
      # @example IgnoredMethods: [homepage_url]
      #   # good - homepage_url is a let-defined helper, not a Rails URL helper
      #   it "renders a link" do
      #     render_inline MyComponent.new
      #     expect(rendered_content).to have_tag("a", href: homepage_url)
      #   end
      #
      class UseWithRequestUrl < RuboCop::Cop::Base
        MSG = "Wrap the render in `with_request_url` when using URL helpers in a component test."

        URL_HELPER_PATTERN = /_(?:path|url)\z/

        RENDER_METHODS = %i[render_inline render_preview].freeze

        def on_def(node)
          return unless node.method_name.to_s.start_with?("test_")
          return unless contains_render_method?(node)
          return if contains_with_request_url?(node)

          each_bare_url_helper(node) do |send_node|
            add_offense(send_node)
          end
        end

        def on_block(node)
          return unless rspec_example_block?(node)
          return unless contains_render_method?(node)
          return if contains_with_request_url?(node)

          each_bare_url_helper(node) do |send_node|
            add_offense(send_node)
          end
        end
        alias on_numblock on_block

        private

        def contains_render_method?(node)
          node.each_descendant(:send).any? do |send_node|
            RENDER_METHODS.include?(send_node.method_name)
          end
        end

        def contains_with_request_url?(node)
          node.each_descendant(:send).any? do |send_node|
            send_node.method?(:with_request_url)
          end
        end

        def each_bare_url_helper(node, &block)
          ignored = ignored_methods
          node.each_descendant(:send) do |send_node|
            next unless send_node.receiver.nil?
            next unless URL_HELPER_PATTERN.match?(send_node.method_name.to_s)
            next if ignored.include?(send_node.method_name.to_s)

            block.call(send_node)
          end
        end

        def ignored_methods
          cop_config.fetch("IgnoredMethods", [])
        end

        def rspec_example_block?(node)
          send_node = node.send_node
          return false unless send_node

          %i[it specify example].include?(send_node.method_name)
        end
      end
    end
  end
end
