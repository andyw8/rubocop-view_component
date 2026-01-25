# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module ViewComponent
    # A plugin that integrates rubocop-view_component with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-view_component",
          version: VERSION,
          homepage: "TODO: Put your plugin's homepage URL here.",
          description: "TODO: Put your plugin's description here."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
