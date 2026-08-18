# frozen_string_literal: true

require "rubocop-view_component"
require "rubocop/rspec/support"
require_relative "support/project_index_helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed

  config.include ViewComponent::ProjectIndexHelpers

  config.before do |example|
    next unless example.metadata[:config]

    graph = build_index
    cop.project_index = ViewComponent::ProjectIndexHelpers::LazyIndex.new(graph, cop)
  end
end
